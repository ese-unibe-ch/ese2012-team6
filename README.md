ese2012-team6
==============

Installation
------------
We are using some additional gems. Please run <code>bundle install</code> to install the gems automatically.
For OSX use a keyword in addition, so run <code>sudo bundle install</code> to install the gems.

Running
-------
All files are placed within a trade folder. To run the app please run 
<code>
cd ese2012-team6
</code>
<code>
ruby /trade/app/app.rb
</code>

Running the app on windows
---------------------------------------------------------
After you've installed rubymine, download Ruby 1.8.7-p330 Binary\n
In Rubymine: Open the properties and choose the Ruby 1.8.7 as SDK.(Usually located at C:Ruby187)\n
Add the path of this folder to the environment variables of the System. (Systemsteuerung\System und \nSicherheit\System => Rechtsklick-Eigenschaften => Umgebungsvariablen => Path: C:\Ruby187\bin)
Install the Devkit
Console: gem install bundler
Console: checkout this project, then use the following command: bundle install
To start the app use: ruby app/app.rb
