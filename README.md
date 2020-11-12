# Lilly App API [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Lilly App API is an API for a mobile app where users can take and store pictures on their phone and in the cloud. Users can share their image bucket with others to look at, as well. There will also be random image retrieval for the app widget to display random pictures from the user's bucket.

## Motivation
My daughter is growing before my eyes - we take a lot of pictures. I wanted a place that my wife and I could upload all the pictures/videos we take of her to be in a shared location that we can share with other family members.

## Code Style
Style defined in .rubocop.yml. Work in progress

## Tech/Framework used
* Rails - API only
* Postgres
* JSON Web Tokens

## Installation
###### This is Mac specific. I have no clue how to run it in Windows
1. Clone this repo:
  `git clone https://github.com/ryanpback/lilly_app_api.git`
2. Install Ruby 2.7
3. Install Rails: `gem install rails`
4. Ensure Postgres is installed
5. Bundle the project:
  `bundle install`
6. Create a Google Cloud account and sign up for a free trial.
7. Create a project
8. [Create a Could Storage service account](https://cloud.google.com/storage/docs/getting-service-account)
9. Download the Google keyfile. And store in the file system
  **Immediately add location of file to your .gitignore**
10. Add environment configuration:
  * To open the config file, run the following in the terminal:
    `EDITOR="<code editor of your choosing> --wait" bin/rails credentials:edit`
  * Add the following keys in the yml file
    ```
    image_upload_name: <this is the name of the key for the image upload> - redacted for security measures
    gcs:
      project_id: <project id from project created above>
      path_to_config: <path the the keyfile you added>
    ```
  * Save and close file to re-encrypt file (confirmation in the terminal)
11. Set up databases for development and testing:
  `rails db:create && rails db:migrate && rails db:test:prepare`

###### You should be setup at this point. Please reach out to me if there are missing steps.

## API Reference
Would eventually like to add swagger to this project.
The following will have to do for now.

Endpoints at the point of writing this:
* Register `/register`:
  - Purpose: Create new user and a new bucket in GCS
  - Method: POST
  - Body:
    + first_name
    + last_name
    + username
    + email
    + password
  - Response
    + Success message/Error
    + New JWT if successful
* Unregister `/users/:id`
  - Purpose: Delete user from Postgres and all GCS data
  - Method: DELETE
  - Headers
    + `Authorization: Bearer <token>`
  - Response
    + Success/Error
* Login `/login`:
  - Purpose: Self explanatory. Retrieve a token
  - Method: POST
  - Body
    + username
    + password
  - Response
    + Successful
      - user
        * id
        * first_name
        * last_name
        * username
        * email
      - token
    + Error
* Save image `/users/:user_id/images`
  - Purpose: Upload and store and image in GCS
  - Method: POST
  - Headers
    + `Authorization: Bearer <token>`
  - Body
    + `<image_upload_name>: <Image object>`
  - Response
    + Success message/Error

## Tests
I'm a firm believer in testing. I try to cover everything.
Run tests with `rspec` from the root directory

## Meta
Ryan Back

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Twitter: [@ryanpback](https://twitter.com/ryanpback)

Email: ryanpback@gmail.com

Github: https://github.com/ryanpback

## Contributing
I mean, if you'd like to, reach out! I don't have anything formal at this time.
