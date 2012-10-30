Trading App ESE 2012 Team 6
==============

Installation
------------

__Windows__

* After you've installed rubymine, download Ruby 1.8.7-p330 Binary (http://www.ruby-lang.org/de/downloads/)
* In Rubymine: Open the properties and choose the Ruby 1.8.7 as SDK.(Usually located at C:Ruby187)
* Add the path of this folder to the environment variables of the System. (Systemsteuerung\System und \nSicherheit\System => Rechtsklick-Eigenschaften => Umgebungsvariablen => Path: C:\Ruby187\bin)
* Install the Devkit (https://github.com/oneclick/rubyinstaller/wiki/Development-Kit)
* Console: <code>gem install bundler</code>
* Console: checkout this project, then use <code>bundle install</code>

__Linux__

You need to have a working version of Ruby 1.8.7 installed on your system. Please refer to your distribution's user forums
on how to install Ruby 1.8.7 on your system. You also have to be able to install third-party gems. (see http://rubygems.org/pages/download)

* open terminal
* Download bundler gem: <code>sudo gem install bundler</code>
* Navigate to project root folder
* Install gems: <code>sudo bundle install</code>

(<code>sudo</code> may or may not be necessary on your system

__Mac OSX__

Ruby 1.8.7 is already pre-installed on OSX. Install bundler gem (see __Linux__) and just run <code>sudo bundle install</code> and type in your admin password to install the required gems.

Running
-------

__Linux and OSX__

All files are placed within a trade folder. To run the app please navigate to the project root and then

<code>
cd trade
</code>

and finally

<code>
ruby app/app.rb
</code>

__Windows__
* Console: navigate to the project root <code>cd ese2012-team6/trade</code>
* To start the app use <code>ruby app/app.rb</code>
