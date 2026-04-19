# AI Translator

A tool to localize text entries from an XCode string catalog (.xcstrings) using the 
OpenAI API, with minimal effort.

## Functionality

The app has the following functions:
* Read a .xcstrings file, and show all the strings to be translated.
* Filter on not-to-be-translated, translated, partially translated and not-translated strings.
* Translate indivual strings via OpenAI.
* Add context to the prompt to drive more tailored translations.
* Choose from a number of different models.
* Batch translate all missing strings via OpenAI.
* Manually edit translations.
* Save in a consistent format to get a manageable diff when making changes.

## Todo

The following things should be added:
* Highlight changes that have not yet been saved.

## Usage

Build with XCode 26.

## Requirements

To translate strings, you need an API Token and enter that in the settings of the app.

## License

The sources are available under the Apache license.
