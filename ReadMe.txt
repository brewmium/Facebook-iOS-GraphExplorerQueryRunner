BASED ON Facebook's GraphAPISample
----------------------------------


Graph Api Explorer Query Runner

Demonstrates the basics of requesting permissions, and executing a query created with the Graph API Explorer tool (https://developers.facebook.com/tools/explorer/).

This app is acting as tho it is the GraphAPISample, so make sure you clear out the permissions for that App from your Facebook App settings if you want to cleanly test new permissions, and what the responding queries look like.

It is IMPORTANT to look at the results of a GraphAPI query ON the device, because the responses you get back on the iOS device (or simulator) are COMPLETELY different than the web based Graph API Explorer.


Using the Sample
----------------
Install the Facebook SDK for iOS.
Drop this Project in along with the other samples installed into the <Facebook SDK>/Samples/ directory.
Launch the GraphExplorerQuerySample (It's still called GraphAPISample) project using Xcode from the <Facebook SDK>/Samples/GraphExplorerQuerySample directory.


Notes
-----
This truly a roughed in testbed App. It has some other needs:

- It should use it's own Name / Facebook App ID. 

- Should use the non deprecated Read/Write based openActiveSessionWith... calls.  (but I didn't get to that in the sample yet. I'll update when I have that.)

- There is a little oddity in that I am embedding the r/w type into the permission name, like "user_photos:r" and "public_actions:w". 
  There are helpers that will separate these for you…  I just wanted it to be less architecture, and more figuring out what was going on.  :-)


Facebook - Feel free to include this in your samples! Just give a bit of credit in some text somewhere

Eric Hayes
Indie/Freelance iOS Developer
www.brewmium.com
