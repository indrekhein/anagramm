# anagramm

Anagramme generator for Estonian

Uses corpus-based word list, generates max two words for output. The dictionary can be freely edited, reordered, tailored, there are no pre-determined limits or order.

(EKI service data: lxc container, /opt/{servicename} directory, internal port 11012)
Ubuntu install inside lxc:
apt install starman libjson-perl
systemctl enable /opt/anagramm/anagramm.service
