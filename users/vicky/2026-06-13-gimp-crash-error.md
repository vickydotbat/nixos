<!-- Copy-paste this whole debug data to report to developers -->

```
GNU Image Manipulation Program version 3.2.4
git-describe: GIMP_3_2_4
Build: unknown rev 0 for linux
# C compiler #
gcc-15.2.0
# Libraries #
using babl version 0.1.126 (compiled against version 0.1.126)
using GEGL version 0.4.70 (compiled against version 0.4.70)
using GLib version 2.88.1 (compiled against version 2.88.1)
using GdkPixbuf version 2.44.6 (compiled against version 2.44.6)
using GTK+ version 3.24.52 (compiled against version 3.24.52)
using Pango version 1.57.1 (compiled against version 1.57.1)
using Fontconfig version 2.17.1 (compiled against version 2.17.1)
using Cairo version 1.18.4 (compiled against version 1.18.4)
using gexiv2 version 0.14.6 (compiled against version 0.14.6)
using exiv2 version 0.28.8

```

> fatal error: Aborted

Stack trace:

```
/nix/store/ym8a4354bsj4hlnxsc30qbwvaq6ijcg4-gimp-3.2.4/lib/libgimpbase-3.0.so.0(gimp_stack_trace_print+0x4d6) [0x7b72a1ee7536]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x2ff75c) [0x5b8a0a81d75c]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x2ffde8) [0x5b8a0a81dde8]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x302db1) [0x5b8a0a820db1]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(+0x42790) [0x7b72a0042790]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(+0x9fdcc) [0x7b72a009fdcc]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(gsignal+0x1e) [0x7b72a004265e]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(abort+0x26) [0x7b72a0029350]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libglib-2.0.so.0(+0x240ee) [0x7b72a185d0ee]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libglib-2.0.so.0(g_log_default_handler+0x10a) [0x7b72a18a8d7a]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libglib-2.0.so.0(g_logv+0x256) [0x7b72a18a9026]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libglib-2.0.so.0(g_log+0x8f) [0x7b72a18a93bf]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgio-2.0.so.0(+0x11a070) [0x7b72a151a070]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x1d568) [0x7b72a19b8568]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x200e8) [0x7b72a19bb0e8]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new_valist+0x68b) [0x7b72a19bd2bb]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new+0x9b) [0x7b72a19bd66b]
/nix/store/v7fvwaf6j1hwvb9dmwfa97nzmrlshqai-gtk+3-3.24.52/lib/libgtk-3.so.0(+0x1acbfc) [0x7b72a09acbfc]
/nix/store/v7fvwaf6j1hwvb9dmwfa97nzmrlshqai-gtk+3-3.24.52/lib/libgtk-3.so.0(+0x1ae950) [0x7b72a09ae950]
/nix/store/v7fvwaf6j1hwvb9dmwfa97nzmrlshqai-gtk+3-3.24.52/lib/libgtk-3.so.0(+0x1a7a69) [0x7b72a09a7a69]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_closure_invoke+0x19c) [0x7b72a19b31bc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2e14a) [0x7b72a19c914a]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2fbcc) [0x7b72a19cabcc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_signal_emit_by_name+0x205) [0x7b72a19d0b05]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x1d568) [0x7b72a19b8568]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_setv+0x152) [0x7b72a19bd7f2]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_set_property+0x1d) [0x7b72a19beb3d]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x1d568) [0x7b72a19b8568]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_set_valist+0x21d) [0x7b72a19bdc8d]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_set+0xb7) [0x7b72a19be9b7]
/nix/store/ym8a4354bsj4hlnxsc30qbwvaq6ijcg4-gimp-3.2.4/lib/libgimpwidgets-3.0.so.0(+0x30a24) [0x7b72a1a30a24]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2010a) [0x7b72a19bb10a]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new_valist+0x68b) [0x7b72a19bd2bb]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new+0x9b) [0x7b72a19bd66b]
/nix/store/ym8a4354bsj4hlnxsc30qbwvaq6ijcg4-gimp-3.2.4/lib/libgimpwidgets-3.0.so.0(gimp_color_profile_chooser_dialog_new+0x2c6) [0x7b72a1a30ea6]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x52545b) [0x5b8a0aa4345b]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_type_create_instance+0x291) [0x7b72a19d7f41]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x1ff74) [0x7b72a19baf74]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new_with_properties+0x24c) [0x7b72a19bc67c]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new+0xc9) [0x7b72a19bd699]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x51a4fb) [0x5b8a0aa384fb]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2010a) [0x7b72a19bb10a]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new_valist+0x68b) [0x7b72a19bd2bb]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_object_new+0x9b) [0x7b72a19bd66b]
/etc/profiles/per-user/vicky/bin/gimp-3.2(gimp_display_shell_new+0xd1) [0x5b8a0aa35af1]
/etc/profiles/per-user/vicky/bin/gimp-3.2(gimp_display_new+0x151) [0x5b8a0aa220f1]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x347e64) [0x5b8a0a865e64]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x340066) [0x5b8a0a85e066]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_closure_invoke+0x19c) [0x7b72a19b31bc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2e74e) [0x7b72a19c974e]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2fbcc) [0x7b72a19cabcc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_signal_emit_valist+0x34) [0x7b72a19d0804]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_signal_emit+0x8f) [0x7b72a19d08cf]
/etc/profiles/per-user/vicky/bin/gimp-3.2(gimp_restore+0x109) [0x5b8a0a626229]
/etc/profiles/per-user/vicky/bin/gimp-3.2(+0x2fec2c) [0x5b8a0a81cc2c]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_closure_invoke+0x19c) [0x7b72a19b31bc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2e14a) [0x7b72a19c914a]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(+0x2fbcc) [0x7b72a19cabcc]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_signal_emit_valist+0x34) [0x7b72a19d0804]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgobject-2.0.so.0(g_signal_emit+0x8f) [0x7b72a19d08cf]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgio-2.0.so.0(g_application_activate+0xa6) [0x7b72a15005b6]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgio-2.0.so.0(+0x100a20) [0x7b72a1500a20]
/nix/store/jlyahda14aya375lv7k9fsin2zk90nxz-glib-2.88.1/lib/libgio-2.0.so.0(g_application_run+0x111) [0x7b72a1500be1]
/etc/profiles/per-user/vicky/bin/gimp-3.2(app_run+0x20d) [0x5b8a0a81d28d]
/etc/profiles/per-user/vicky/bin/gimp-3.2(main+0x39b) [0x5b8a0a6241fb]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(+0x2b285) [0x7b72a002b285]
/nix/store/57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61/lib/libc.so.6(__libc_start_main+0x88) [0x7b72a002b338]
/etc/profiles/per-user/vicky/bin/gimp-3.2(_start+0x25) [0x5b8a0a624465]

```
