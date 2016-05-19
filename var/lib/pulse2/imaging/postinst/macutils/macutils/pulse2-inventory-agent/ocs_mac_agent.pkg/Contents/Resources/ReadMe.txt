This agent acts much like the OCS Inventory Agent for Windows & Linux.  It gathers data (mostly using system_profiler) about the computer it is running on and dumps all the data either into an XML file or it posts it to the OCS communications server.  It gathers all of the same data as the Windows agent except Accesses, Ports, Registry, Slots, and Sounds which either aren't applicable on Macs or I haven't found a way to gather the data for them.  It only works on OSX 10.3+ because 10.3 was the first version to have PHP installed by default.  I use PHP because I know it well, it comes installed on all

INSTALLATION
The agent will run at bootup and will work without any configuration changes IF your communication server is named "ocsinventory-ng".  If your server is named differently or you want to change the settings (such as the TAG), the config files are located in /etc/ocsinventory-client/.  The actual script is located in /usr/local/sbin/ocs_mac_agent.php

Note that this version of the agent only works with the latest version of OCS (OCS-NG).  If you are using OCS 3.0 you will need to use an older version of the agent.

You can learn more about OCS Inventory at 
http://ocsinventory.sourceforge.net/

The latest version of OCS Mac Agent can be found at 
http://codejanitor.com/

Thanks to Brooks Institute of Photography (brooks.edu) for allowing this package to be open sourced.
