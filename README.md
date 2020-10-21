Google Calendar To Ical
---

Converts the next week of google calendar events to an ical on localhost.

Google Calendar often has public ical set to hide event details. This uses the Google Calendar API to pull event details and build our own ical served on localhost behind HTTP Basic Auth.

How to run
---
1. Run `cp .env.example .env`
2. Get a Google Client ID and Secret (see below)
3. Add your Calendar ID (usually your GSuite Email), or open the "settings" for your calendar and scroll to "Integrate" to find your Calendar ID
4. Add a username and password for your HTTP basic auth
5. Ensure the timezone is correct in `.env`
6. Run `bundle install`
7. Run `bundle exec ruby cal.rb`
   - The first run will prompt you to authenticate with Google
   - It will then provide you with a Refresh Token online, save this in `.env`
   - Now you won't have to authenticate again
8. Hit `http://localhost:8080/calendar.ical` and enter the user name and password you chose and an `ical` should be downloaded

Google Client ID & Secret
---
Obtain a Client ID and Secret

1. Open [Google Developers Console](https://console.developers.google.com/)
2. Select or create a project at the top of the page.
3. Select Library in the left sidebar
4. Search for in 'Google Calendar', and enable 'Google Calendar API' from the results.
5. Select Credentials in the sidebar
6. Create your 'OAuth client ID' by clicking "Create Credentials"
   - Note: you will need to setup the OAuth consent screen before you can create your client ID. There should be a link or prompt on the screen
7. Select the 'Other' option and click create.
8. Add the Client ID and Secret to `.env`
