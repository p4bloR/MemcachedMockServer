Welcome!

This readme file contains:
- A quick explanation of project's architecture
- Requirements
- Steps to run a server and clients
- Sample commands
- Steps to run tests

- A quick explanation

This project uses Client-Server architecture. The whole program is made of 4 classes: Server, Client, MemObject and Database.
The server class opens a localhost TCP Server on a desired port. A timer runs on a parallel thread to detect and delete any expired keys. The Server accepts all incoming connections opening a new thread for each. Clients connect to the TCP Socket and run two parallel threads, one is constantly listening for responses from the Server while the other is always read to send user input to the server. The Server allows users to create and edit MemObjects (short for Memcached Objects), these are saved in the volatile database created by the Database class until they expire. Diagrams are included in the diagrams folder


- REQUIREMENTS:

- Use ubuntu (you can use a Virtual Machine if necessary)
- Install ruby 2.7 or higher. Here is a tutorial on how to install the latest version of ruby: https://zoomadmin.com/HowToInstall/UbuntuPackage/ruby-rspec
- Instal rspec 3.9 or higher. Here is a tutorial on how to install the latest version of rspec: https://zoomadmin.com/HowToInstall/UbuntuPackage/ruby-rspec
 (rspec packages listed below)
  - rspec-core 3.9.1
  - rspec-expectations 3.9.0
  - rspec-mocks 3.9.1
  - rspec-support 3.9.2

- Steps to run a Server and a client

1. Open the ubuntu terminal and navigate to the MemcachedMockServer folder
2. Enter the "lib" folder
3. Enter the following command on the terminal: ruby RunServer.rb
   The server should ask you to enter a port number or "exit"
   After entering a free port number the success message "Server is running"
   should appear
4. Open a new tab on the terminal, and without leaving the lib folder
   enter the following command: ruby RunClient.rb
5. Enter the same port the server is running on, you should get a 
   "connected to server" message
6. Now you have successfully connected a client to the server, you can
   connect as many clients as you like by repeating step 4.
  
  With the client connected now you can execute set, get, gets, add, replace, append, prepend and cas commands just like in real memcached server. You can also enter "close server" to close the server, or "close client" to close that clients session.
  
- Sample commands
This is a list of sample commands you can use to test all memcached commands. Once you want to close the server just enter "close server".

Let's add something
User input: "add element1 0 900 2"
User input: "hi"
Response: "STORED"

Retrieve it
User input: "get element1"
Response: "VALUE element1 0 2"
Response: "hi"
Response: "END"

Override it
User input: "set element1 0 900 5"
User input: "hello"
Response: "STORED"

Add another one
User input: "add element2 0 900 4"
User input: "hola"
Response: "STORED"

And retrieve both
User input: "get element1 element2"
Response: "VALUE element1 0 5"
Response: "hello"
Response: "VALUE element2 0 4"
Response: "hola"
Response: "END"

Lets use the replace command
User input: "replace element2 0 900 7"
User input: "wassup?"
Response: "STORED"

And retrieve to see if it worked
User input: "get element2"
Response: "VALUE element2 0 7"
Response: "wassup?"
Response: "END"

Now we try append
User input: "append element1 0 900 14"
User input: ", how are you?"
Response: "STORED"

And also prepend
User input: "prepend element2 0 900 5"
User input: "hey, "
Response: "STORED"

And check the results
User input: get element1 element2
Response: "VALUE element1 0 19"
Response: "hello, how are you?"
Response: "VALUE element2 0 12"
Response: "hey, wassup?"
Response: "END"

Lets use gets to get the CAS data
User input: "gets element1"
Response: "VALUE element1 0 19 5"
Response: "hello, how are you?"
Response: "END"

And let's use cas
User input: "cas element1 0 900 3 5"
User input: "bye"
Response: "STORED"

User input: "get element1"
Response: "VALUE element1 0 3"
Response: "bye"
Response: "END"

Now let's try cas again using the same cas number, it shouldn't work.
Cas should
User input: "cas element1 0 900 6 5"
Response: "EXISTS"

Let's check the expiring

User input: "add element3 0 1 9"
User input: "disappear"
Response: "STORED"

Wait two seconds and the element should be gone
User input: "get element3"
Response: "END"

By now you tried every available spec command at least once.

- How to run rspec tests

1. Make sure there are no instances of server or or client running. 

2. Through the terminal, go to the specs folder (MemcachedMockServer/spec)
3. Now enter: rspec Commands_spec.rb
   After printing a lot of messages into the console the following success
   message should appear "28 examples, 0 failures"   
   
4. This rspec test uses the port 8080 by default, in case you get an error because the port is already in use. Open the "Test_settings.txt" on the specs folder and change the port value to one that is not being used. 
