FSAE Telemetry - Realtime remote datalogging
====================================================
![T52ERacinglogo](https://cloud.githubusercontent.com/assets/8706609/5561667/f85d0604-8e3a-11e4-96cd-d9dd6ca99271.png)

FSAE Telemetry is a realtime remote datalogging and debugging solution, built as a group project for Royal Melbourne Institute of Technology, Design 3AB alongside the 2014 RMIT Electric Racing team.

The SAE-A hosts the annual Formula SAE-A event. This is a 3 day international, student engineering competition centred on the design, construction and racing of a 600cc race car. The competition presents students with the opportunity to develop their skills in design, management, manufacturing, communication, research and business operations in a real world environment.

RMIT Electric Racing formed in 2008 and was the first ever electric vehicle built for the Formula SAE competition. Built on the success of over a decade of RMIT Racing, a small team of interested students and staff at RMIT set out to prove that they could produce a simple, completely electric counterpart for the combustion vehicle competition. Since its inception in 2008 at RMIT, every year Formula SAE globally has seen a rapid growth in the number and competitiveness of electric vehicles. In Australia, RMIT Electric Racing continues to be the number 1 placed electric vehicle, and is every year outperforming more and more combustion rivals. RMIT Electric Racing is fully-committed to sustainable engineering. Our mission is to promote the viability and exciting future of electric cars through not only showing we can compete with combustion powered cars, but by besting them.


Follow [@RMITeRacing](http://twitter.com/RMITeRacing) on twitter for all RMIT Electric Racing updates.

![logo + datalog ui build 1.0](https://cloud.githubusercontent.com/assets/8706609/5561645/1524dd4a-8e39-11e4-8fe7-7c231f25e5e9.png)

Purpose
-------

The primary goals of the FSAE Telemetry system can be summarized by the following criteria:

1.	Create a reliable wireless link between vehicle and a remote location
2.	Provide real-time plotting capabilities for various sets of data
3.	Enable logging functionality to store data for later reference
4.	Ensure extensive error handling to manage data corruption do to transmission issues
5.	Preserve data in instances of transmission disruption
6.	Design system such that it can be completely controlled by the remote interface


Installation and usage
----------------------

You'll need [Energia](http://energia.nu/download/). Download Release 0101E0012 or Release 0101E0013 if you're unsure, of the latest build's libraries.

Alongside Energia you will need [Processing](http://processing.org/download/?processing). if you have encounter issues it's advised that you try build 2.2.1

# > Install #

	Download or clone the repository, to you local machine.

# > Hardware #
Transmitter End:

    Launchpad EK-TM4C123GXL (Tiva C Series TM4C123G LaunchPad)
	Connected to Paired Xbee Pro 900HP via Serial port 2
	Debugport, bound to Serial port 1

Receiver End:

    Simple FTDI USB to Serial Module connected to a Paired Xbee Pro 900HP

# > Software #
Transmitter End:

    Within "Launchpad_Data_Processor/", Launchpad_Data_Processor.ino
	Caution: This is a Energia ino file! (NOT an arduino ino)
	
	Open with Energia

	IDE settings:
		Tools>Board>(Your devboard/microcontroller)
		Serial Port>(Serial Port your microcontroller is connected)

	Code:
		Set program parameters.

	Compile:
		Top Left, tick icon(verify)
		Top Left, right_arrow icon(upload to microcontroller)

Receiver End:

    Within "Processing_Data_Logger_with_Timebase/MainProcessing/", MainProcessing.pde
	Caution: This is a Processing pde file! (NOT an arduino pde)

	Open with Processing

	IDE settings:
		All default, settings.
		Top Right, Mode:Java.

	Code:
		Set program parameters.

		To note, remember to set
		Baudrate, default 115200
		Serial Port name, eg "COM3", "COM4", "/dev/ttyS0"

	Compile:
		For program to compile you will require, controlP5.
		http://www.sojamo.de/libraries/controlP5/

		Top Left, play icon(run)

Official repository
-------------------------------

The official repo and support issues/tickets live at [github.com/T52/](http://github.com/T52/T52_FSAE_Telemetry).


Contributors
------------

* [Rob Hutchinson](http://github.com/robhutch)
* [Wilson Mok](http://github.com/infrequent)
* [Matt Jane](http://github.com/mattjane)
* [Ed Martell](http://github.com/cyphron)

License
-------

All directories and files are MIT Licensed.
