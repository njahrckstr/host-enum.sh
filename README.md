# host-enum.sh
# This script is a simply portscanner that I found while going through my OSCP. Decided to put it on my Github page because I was tired of downloading it every time I stood up a new image. At least I know where it is now. 
# Usage: host-enum.sh IP
# Testing on the latest Kali 2018 image and works just fine.
#to run this on a range and log the output at the same time
#   for i in $(seq 200 254); do bash host-enum.sh x.x.x.$i | tee -a host-enum/all.txt; done
#
#open the results all pretty like..
#   zenmap -f *.xml #this assumes you have changed the nmap command to log to xml
#----------------------------------------------------------------

#obviously a LOT more scripts can be added, I have left the original ones and will be adding more as I feel necessary. This list does not include any brute, exploit, dos, or auth scripts just like the original.
