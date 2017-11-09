# AddNewPilots
This script was created to automate the creation process for new pilots. A new hire roster is sent to the helpdesk,
usually sent by Eric Cannon. The information from that email is then copied and transposed into the Excel 
template "NewPilotTemplate".This template takes the information, breaks up address fields and selects an appropriate 
template account based on the pilot's reporting base. Once the information is entered, it should be Saved As 
a csv file with the name "NewPilots" in the same directory. The script can then be run, referencing the newly 
created file.The script sets variables such as the temporary password for the user account and the location of the 
csv file. It then goes into a loop for each user listed in the file and sets the variables for Full name, samAccount 
name, and user profile name. Once the variables are set, it creats a new user based on the appropriate template, and
sets the properties of the user based on the information in the CSV.
