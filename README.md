# Memory Hog

This is an app you can build and install on an iOS device to help _**chew up**_ memory. Why would you want to do that? Well, for those times when you want to verify how the app you are developing or debugging behaves under conditions of low available memory. 

* Apple's Watchdog is quick to terminate apps that are consuming large quantities of memory when they are in the background if the foreground app needs memory. Because of this its best use to _Memory Hog_ on an iPad using a split screen showing it and he app you are debugging

* One thing you will notice is that the OS will flag low memory warnings long before the actual available memory is exhausted. That's because it does not want any single app to use all the memory. If you want to live on the edge you can tell _Memory Hog_ to ignore any low memory warnings coming from the OS. Of course, this does mean _Memory Hog_ might terminate unexpectedly.

* You will see differences in the numbers shown in the app versus those shown in Xcode. There is no public API available that provides for the exact same reporting of used memory or memory used by other apps. The numbers displayed in the "Device Memory" section are a general reference.

* Debugging memory usage issues is hard, so use this tool to help your efforts but don't expect it to magically find your issues on its own.

<br>

<img src='/Images/Screenshot1.png' width='550' border='0' alt='A screenshot of the primary screen of the app' />

<br>
If you want to support my work, you can by me a coke zero... <br><br>

<a href='https://ko-fi.com/F1F4UHD6J' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi1.png?v=3' border='0' alt='Buy Me a Coke Zero at ko-fi.com' /></a>