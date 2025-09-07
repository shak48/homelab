remove target  hostkeys
ssh-keygen -f "/home/rumie/.ssh/known_hosts" -R "192.168.0.121"


6.5 Print Server CUPS
6.5.1 VM Setup
6.5.1.1 To set up CUPS. Run the “print-server” play. 
ansible-playbook playbooks/create-print-server.yml --ask-vault-pass
6.5.1.2 If the printer is not added properly, connect the printer via USB port and add the printer from hardware properties.
6.5.1.2.1 The set up is optimized for an EPSON ET-2850 series printer. Therfore, changes may be made to accommodate for a different series printer.
6.5.1.2.2 TODO: Add roles for automatically adding the printer via USB.
6.5.2 Fine Tuning
6.5.2.1 Printer Side
6.5.2.1.1 Goto the printer UI and reset all settings.
6.5.2.1.2 Turn the WIFI off, we don’t need it anymore!
6.5.2.1.3 To help suppress some warnings related to page size, disable auto page size switching and then set paper size to A4.
6.5.2.1.4 Finally, save all changes.
6.5.2.2 Server Side
6.5.2.2.1 Navigate to server ip:631/admin. We can use server root credentials to authorize any changes.
6.5.2.2.2 Next, click “Add Printer” and pick one from local.
6.5.2.2.3 Check to share the printer if not already set bu Ansible.
6.5.2.2.4 For driver, it was found that “IPP Everywhere” works better than “Epson factory driver” or “Driverless” configuration. Also, it appears that factory driver seems to execute print job super slow!
6.5.2.2.5 Add Printer and authorize by entering the root credentials.
6.5.2.2.6 Also, make changes “Set Default Options” to change the paper size to A4 if not set already.
6.5.2.3 User Side
6.5.2.3.1 On a windows machine, add the printer.
6.5.2.3.2 Then go to settings to set the paper size to A4.
6.5.2.3.3 Click apply to apply all changes. This should suppress the warnings related to paper size mismatch warnings.
