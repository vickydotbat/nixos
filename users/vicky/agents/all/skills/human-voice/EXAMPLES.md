# Before and after

Pairs for the tells that are hard to spot in your own draft. Each "after" is
shorter and carries more fact than its "before".

## Puffery

- **Before:** The library provides a robust, comprehensive solution for
  handling dates in a seamless way.
- **After:** The library parses and formats dates, including time zones and
  leap seconds.

## Significance talk

- **Before:** The 2.0 release marks a pivotal moment in the project's
  evolution.
- **After:** Version 2.0 dropped Node 16 support and cut the bundle by 40%.

## Participle tails

- **Before:** The cache stores results for an hour, significantly improving
  performance and enhancing the user experience.
- **After:** The cache stores results for an hour. Repeat searches return in
  about 20 ms instead of 400 ms.

## Negative parallelism

- **Before:** This isn't just a config file — it's the single source of truth
  for the whole deployment.
- **After:** This config file is the source of truth for the whole deployment.

## The rule of three

- **Before:** The API is fast, flexible, and easy to use.
- **After:** The API answers in under 50 ms.

Also watch for triads stacked across neighbouring sentences, which is the
louder version of the same tell.

## Dodging "is"

- **Before:** The `parse()` function serves as the main entry point and
  functions as a validator.
- **After:** `parse()` is the entry point. It also validates the input.

## Elegant variation

- **Before:** Set the limit in the config. This threshold applies per user, and
  the cap resets nightly.
- **After:** Set the limit in the config. The limit applies per user and resets
  nightly.

## Vague sourcing

- **Before:** Experts generally recommend rotating keys regularly.
- **After:** The OWASP cheat sheet recommends rotating keys every 90 days.

## Formula ending

- **Before:** Despite its simple design, the tool faces challenges common to
  command-line utilities. Overall, it remains a valuable addition to any
  workflow.
- **After:** It has no Windows build yet. (Then stop.)

## Inline-header bullets

- **Before:**
  - **Speed**: Requests finish faster.
  - **Safety**: Bad input is rejected.
  - **Cost**: Fewer servers are needed.

- **After:** Requests finish in half the time, bad input is rejected at the
  edge, and the service now runs on two machines instead of five.

Keep the bullet form when the items really are a list a reader will scan or
come back to — flags, options, steps.

## Even rhythm

- **Before:** The parser reads the file line by line. It builds a tree from the
  tokens it finds. The tree is then passed to the printer for output.
- **After:** The parser reads the file line by line and builds a tree from the
  tokens. The printer takes it from there.
