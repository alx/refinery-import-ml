# Refinerycms Mailing-List import

At Tetalab, most of our content is generated on our mailing-list.

Because we want people to read some of this content on the website, and without subscribing on the mailing list, this script helps with reading mails from a gmail account, select the interesting subjects, and import the content in refinerycms-blog engine.

## Configuration

* copy _config.yml.sample_ to _config.yml_
* insert your gmail details in config.yml
* insert the path to your production sqlite3 db in config.yml

## Usage

* Display all avalaible mail for import:

    ruby mailing.rb

* Select a particular mail in this list:

    ruby mailing.rb 3

* Mark all mails as read

    ruby mailing 0
