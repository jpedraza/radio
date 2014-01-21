# radio

Caches songs from a Pandora radio station to avoid latency issues on bad WiFi.

## Setup

1. Install the necessary dependencies.

   ```
   brew install ffmpeg mpg123 portaudio
   ```

2. Install the necessary libraries.

   ```
   bundle install
   ```

3. Create a `.pandora` configuration file.

   ```yaml
   username: "USERNAME"
   password: "PASSWORD"
   station:  "STATION NAME"
   ```

## Usage

1. Run the application.

   ```
   ruby application.rb
   ```

2. Open the interface.

   ```
   open http://localhost:4567/
   ```

3. Use the shortcut keys for control. Space to pause or play, and N to go to the next song.

## License

radio uses the MIT license. See LICENSE for more details.
