#!/usr/bin/env python3

# ##### BEGIN GPL LICENSE BLOCK #####
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 3
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software Foundation,
#  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# ##### END GPL LICENSE BLOCK #####

import gi
gi.require_version('Gimp', '3.0')
from gi.repository import Gimp
gi.require_version('Gegl', '0.4')
from gi.repository import Gegl
from gi.repository import GObject
from gi.repository import GLib
from gi.repository import Gio

import os
import sys
import struct
from array import array

# Possible color formats for reading a drawable's buffer: https://gegl.org/babl/Reference.html
# "Y'A u8"  => Grayscale, separate alpha
# "Y'aA u8" => Grayscale, associated alpha
# "YA u8"   => Luminance, separate alpha
# "YaA u8"  => Luminance, associated alpha

PLT_HEADER_4CC     = 'PLT '
PLT_HEADER_VERSION = 'V1  '

# New layers can easily be added by extending this list, the script
# will automatically include them
# Add them to the end, list-position = plt-channel-idx (skin = 0)
PLT_CHANNELS = ["skin", "hair", "metal1", "metal2", "cloth1", "cloth2",
                "leather1", "leather2", "tattoo1", "tattoo2"]

# Alpha value at which to consider a pixel of layer to be set, range [0,255]
PLT_ALPHA_CUTOFF = 25


def thumbnail_plt(procedure, file, thumb_size, args, data):

    # Gimp Load procedures file parameter has type "GLocalFile"
    # I really can't be bothered to divine the python docs from the C docs
    # I'm using the standard python function to handle files
    filepath = file.peek_path()
    image = None
    with open(filepath, 'rb') as plt_file:
        # Unpack Header
        # "PLT " + "V1  " + MaxSupportedChannels? + Unused + Width + Height
        four_cc, _, width, height = struct.unpack('<4s4s8x2I', plt_file.read(24))
        if four_cc.decode(encoding='ascii', errors='ignore') != PLT_HEADER_4CC:
            return Gimp.ValueArray.new_return_values(GObject.Value(Gimp.PDBStatusType,
                                                     Gimp.PDBStatusType.EXECUTION_ERROR))

        num_pixels = width * height
        rectangle = Gegl.Rectangle.new(0, 0, width, height)

        # plt consists of (color, channel) tuples, but we don't care about
        # the channel here. Just skip every other byte
        plt_pixels = plt_file.read()[::2]
        # Transform coordinates (plt: bottom left origin => gimp: top left origin)
        plt_pixels = [px for i in range(height) for px in
                      plt_pixels[(height*width)-((i+1)*width):(height*width)-(i*width)]]

        # Create the gimp image,
        # Note: We don't need an alpha channel here
        image = Gimp.Image.new(width, height, Gimp.ImageBaseType.GRAY)
        image.undo_disable()
        layer = Gimp.Layer.new(image, "layer", width, height, Gimp.ImageType.GRAY_IMAGE, 0, Gimp.LayerMode.NORMAL)
        layer_buffer = layer.get_buffer()
        layer_buffer.set(rectangle, "Y' u8", plt_pixels)  # "Y' u8" = Luminance without alpha
        layer_buffer.flush()
        layer.merge_shadow(False)
        layer.update(0, 0, width, height)
        image.insert_layer(layer, None, 0)

        # Seems like thumbnails are always square, so we need to make sure
        # the longest size is of size thumb_size
        #image.scale(min(width, thumbsize), min(height, thumbsize))

    if image:
        return Gimp.ValueArray.new_from_values([
            GObject.Value(Gimp.PDBStatusType, Gimp.PDBStatusType.SUCCESS),
            GObject.Value(Gimp.Image, image),
            GObject.Value(GObject.TYPE_INT, width),
            GObject.Value(GObject.TYPE_INT, height),
            GObject.Value(Gimp.ImageType, Gimp.ImageType.GRAY_IMAGE),
            GObject.Value(GObject.TYPE_INT, 1)
        ])

    # Something went wrong with opening the file
    return Gimp.ValueArray.new_return_values(GObject.Value(Gimp.PDBStatusType,
                                             Gimp.PDBStatusType.EXECUTION_ERROR))


def export_plt(procedure, run_mode, image, file, options, metadata, config, data):

    # Create a temp image to have gimp handle necessary operations
    temp_image = image.duplicate()
    temp_image.undo_disable()

    # We need a grayscale image, convert if necessary
    if (temp_image.get_base_type() != Gimp.ImageBaseType.GRAY):
        temp_image.convert_grayscale()


    # Search for layers containing plt data and save which plt layer
    # corresponds to which gimp layer
    # 1. Look for matching names
    layer_map = []
    for layer in temp_image.get_layers():
        layer_name = layer.get_name().lower()
        if layer.get_visible() and layer_name in PLT_CHANNELS:
            layer_map.append((PLT_CHANNELS.index(layer_name), layer))
    # 2. Fallback: No layers have been found
    #              Use the 10 top most layers instead
    if not layer_map:
        layer_map = [(plt_channel_idx, layer) for plt_channel_idx, layer in enumerate(temp_image.get_layers()[:10])]

    # Might still be empty because no visible layers
    if not layer_map:
        temp_image.delete()
        return Gimp.ValueArray.new_from_values([GObject.Value(Gimp.PDBStatusType, Gimp.PDBStatusType.EXECUTION_ERROR)])
    Gimp.progress_init("Exporting Packed Layer Texture")
    Gimp.progress_update(0.0)

    # Get img data
    width = temp_image.get_width()
    height = temp_image.get_height()
    num_pixels = width * height
    rectangle = Gegl.Rectangle.new(0, 0, width, height)
    plt_pixels = [(255, 0)] * num_pixels  # Init all plt pixels with (white, channel 0)
    # file parameter is of type GLocalFile, can't be bothered to divine the python docs,
    # doing it the standard python way
    filepath = file.peek_path()
    with open(filepath, 'wb') as plt_file:
        # Write header
        Gimp.progress_set_text("Writing header")
        plt = struct.pack('<4s4s2I2I', PLT_HEADER_4CC.encode('ascii'), PLT_HEADER_VERSION.encode('ascii'), 10, 0, width, height)
        plt_file.write(plt)

        # We go in reverse, that way we process the lower most layer first,
        # overwriting a pixel, if a pixel in an upper layer is present/visible
        for plt_channel, layer in reversed(layer_map):
            Gimp.progress_set_text("Packing layer " + layer.get_name())
            # Setup the layer for export, i.e. make sure wysiwyg
            layer.resize_to_image_size()
            layer.merge_filters()
            layer.remove_mask(Gimp.MaskApplyMode.APPLY)
            # Grab image data directly from the drawable(=layer) buffer
            layer_pixels = layer.get_buffer().get(rectangle, 1.0, None, Gegl.AbyssPolicy(0))
            if layer.has_alpha():
                # Go over all pixels in this layer and overwrite the color value in the plt if there is a visible layer pixels
                # Using an alpha threshold instead of 0 (ideally the user would have run Layer => Transparency => Threshold alpha before exporting)
                plt_pixels = [(lay_px[0], plt_channel) if lay_px[1] > PLT_ALPHA_CUTOFF else plt_px
                              for plt_px, lay_px in zip(plt_pixels, zip(*[iter(layer_pixels)]*2))]
            else:
                # No alpha, overwrite everything (layer is 1bpp)
                plt_pixels = [(color, plt_channel) for color in layer_pixels]

        # No longer needed
        temp_image.delete()

        # Transform coordinates (gimp: top left origin => plt: bottom left origin)
        plt_pixels = [px for i in range(height) for px in plt_pixels[num_pixels-((i+1)*width):num_pixels-(i*width)]]
        plt_data = struct.pack('<' + str(num_pixels*2) + 'B', *[i for sl in plt_pixels for i in sl])
        plt_file.write(plt_data)

    Gimp.progress_update(1.0)
    Gimp.progress_end()

    return Gimp.ValueArray.new_from_values([
        GObject.Value(Gimp.PDBStatusType,
        Gimp.PDBStatusType.SUCCESS)
    ])


def load_plt(procedure, run_mode, file, metadata, flags, config, data):

    Gimp.progress_init("Loading  Packed Layer Texture")
    Gimp.progress_update(0.0)

    # Gimp Load procedures file parameter has type "GLocalFile"
    # I really can't be bothered to divine the python docs from the C docs
    # I'm using the standard python function to handle files
    filepath = file.peek_path()
    image = None
    with open(filepath, 'rb') as plt_file:
        # Unpack Header
        # "PLT " + "V1  " + Width + Height
        Gimp.progress_set_text("Unpacking Header")
        four_cc, _, width, height = struct.unpack('<4s4s8x2I', plt_file.read(24))
        if four_cc.decode(encoding='ascii', errors='ignore') != PLT_HEADER_4CC:
            Gimp.message("Not a valid PLT file")
            return Gimp.ValueArray.new_from_values([GObject.Value(Gimp.PDBStatusType,
                                                    Gimp.PDBStatusType.EXECUTION_ERROR)])

        num_pixels = width * height
        num_layers = len(PLT_CHANNELS)
        rectangle = Gegl.Rectangle.new(0, 0, width, height)

        # Now read (color, layer) tuples - 1 byte each
        Gimp.progress_set_text("Unpacking Data")
        plt_pixels = [struct.unpack('<2B', plt_file.read(2)) for i in range(num_pixels)]
        # Transform coordinates (plt: bottom left origin => gimp: top left origin)
        plt_pixels = [px for i in range(height) for px in
                      plt_pixels[num_pixels-((i+1)*width):num_pixels-(i*width)]]

        # Create the gimp image
        image = Gimp.Image.new(width, height, Gimp.ImageBaseType.GRAY)
        # image.set_file(os.path.split(filename)[1])  # No workey here, only for xcf files
        image.undo_disable()
        for plt_channel, layer_name in enumerate(PLT_CHANNELS):
            Gimp.progress_set_text("Creating " + layer_name + " layer")
            layer = Gimp.Layer.new(image, layer_name, width, height, Gimp.ImageType.GRAYA_IMAGE, 100, Gimp.LayerMode.NORMAL)
            # Grab the layer buffer to set all pixels at once
            layer_buffer = layer.get_buffer()
            #layer_pixels = layer_buffer.get(rectangle, 1.0, None, Gegl.AbyssPolicy(0))
            # Grab only those pixels that belong to the currrent plt channel, the others will be transparent
            temp = [[p[0], 255] if p[1] == plt_channel else [0, 0] for p in plt_pixels]
            temp = array('B', [i for sl in temp for i in sl]).tobytes()
            # Write
            layer_buffer.set(rectangle, "Y'A u8", temp)  # "Y'A u8" = Luminance with seperate alpha
            layer_buffer.flush()
            layer.update(0, 0, width, height)
            image.insert_layer(layer, None, 0)
            Gimp.progress_update(float(plt_channel+1)/float(num_layers))

        image.undo_enable()

        Gimp.progress_update(1.0)
        Gimp.progress_end()

    if image:
        return Gimp.ValueArray.new_from_values([
            GObject.Value(Gimp.PDBStatusType, Gimp.PDBStatusType.SUCCESS),
            GObject.Value(Gimp.Image, image),
        ]), flags

    # Something went wrong
    return Gimp.ValueArray.new_return_values(GObject.Value(Gimp.PDBStatusType, Gimp.PDBStatusType.EXECUTION_ERROR))


def setup_plt(procedure, run_mode, image, drawables, config, run_data):

    def get_plt_layer_position(plt_channel_id, existing_layers):
        # Loop though preceeding plt_ids and check if they are present
        search_id = plt_channel_id+1
        while search_id < len(PLT_CHANNELS):
            if PLT_CHANNELS[search_id] in existing_layers:
                return existing_layers[PLT_CHANNELS[search_id]]+1
            search_id += 1
        return 0

    #Gimp.message_set_handler(Gimp.MessageHandlerType.CONSOLE)
    #Gimp.message("setup_plt")

    layer_width = image.get_width()
    layer_height = image.get_height()

    # Make sure layer type matches image type, get the type of layer from image type
    layer_type = Gimp.ImageType.GRAYA_IMAGE
    if image.get_base_type() == Gimp.ImageBaseType.RGB:
        layer_type = Gimp.ImageType.RGBA_IMAGE
    elif image.get_base_type() == Gimp.ImageBaseType.INDEXED:
        layer_type = Gimp.ImageType.INDEXEDA_IMAGE

    # Get all layer names from the current image, mapped to their index
    existing_layers = {l.get_name():i for i, l in enumerate(image.get_layers())}
    for plt_channel_id, plt_channel_name in enumerate(PLT_CHANNELS):
        Gimp.message(plt_channel_name)
        # We don't want to create already existing plt layers
        if plt_channel_name not in existing_layers:
            # Insert at the correct position in case the layers exist partially
            layer_position = get_plt_layer_position(plt_channel_id, existing_layers)
            # Create an insert layer
            layer = Gimp.Layer.new(image, plt_channel_name, layer_width, layer_height, layer_type, 100, Gimp.LayerMode.NORMAL)
            layer.fill(Gimp.FillType.TRANSPARENT)
            image.insert_layer(layer, None, layer_position)

    return procedure.new_return_values(Gimp.PDBStatusType.SUCCESS, GLib.Error())


class FileBioPlt(Gimp.PlugIn):

    def do_set_i18n(self, procname):
        return True, 'gimp30-python', None

    def do_query_procedures(self):
        return ['file-bioplt-setup',
                'file-bioplt-thumbnail',
                'file-bioplt-load',
                'file-bioplt-export']

    def do_create_procedure(self, name):
        if name == 'file-bioplt-export':
            procedure = Gimp.ExportProcedure.new(self, name,
                                                 Gimp.PDBProcType.PLUGIN,
                                                 False, export_plt, None)
            procedure.set_image_types('*')
            procedure.set_documentation("Export a Packed Layer Texture (.plt)",
                                        "Export a Packed Layer Texture (.plt)",
                                        name)
            procedure.set_menu_label('Packed Layer Texture')
            procedure.set_extensions("plt")
        elif name == 'file-bioplt-load':
            procedure = Gimp.LoadProcedure.new(self, name,
                                               Gimp.PDBProcType.PLUGIN,
                                               load_plt, None)
            procedure.set_menu_label("Packed Layer Texture")
            procedure.set_documentation("Load a Packed Layer Texture (.plt)",
                                        "Load a Packed Layer Texture (.plt)",
                                        name)
            procedure.set_mime_types('image/bioplt')
            procedure.set_extensions('plt')
            procedure.set_thumbnail_loader('file-bioplt-thumbnail')
        elif name == 'file-bioplt-thumbnail':
            procedure = Gimp.ThumbnailProcedure.new(self, name,
                                                    Gimp.PDBProcType.PLUGIN,
                                                    thumbnail_plt, None)
            procedure.set_documentation("Load a thumbnail for a Packed Layer Texture (.plt)",
                                        "Load a thumbnail for a Packed Layer Texture (.plt)",
                                        name)
        else:  # name == 'file-bioplt-setup'
            procedure = Gimp.ImageProcedure.new(self, name,
                                                Gimp.PDBProcType.PLUGIN,
                                                setup_plt, None)
            procedure.set_image_types('*')
            procedure.set_menu_label("Add Missing Plt Layers")
            procedure.set_documentation("Add missing layers for a Packed Layer Texture",
                                        "Add missing layers for a Packed Layer Texture",
                                        name)
            procedure.add_menu_path('<Image>/Tools/Neverwinter Nights/')

        procedure.set_attribution('Attila Gyoerkoes', 'Attila Gyoerkoes', '2025')
        return procedure


Gimp.main(FileBioPlt.__gtype__, sys.argv)
