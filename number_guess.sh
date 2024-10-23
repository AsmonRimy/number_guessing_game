#!/bin/bash

# Connect to the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Function to get user data
get_user_data() {
  USERNAME=$1
  USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")
  echo "$USER_DATA"
}

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if user exists in the database
USER_DATA=$(get_user_data "$USERNAME")

if [[ -z $USER_DATA ]]; then
  # If the user is new, insert them into the database
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Initialize games_played and best_game
  GAMES_PLAYED=0
  BEST_GAME=0
  # Insert new user into the database
  $PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', $GAMES_PLAYED, $BEST_GAME);"
else
  # If the user exists, retrieve their games_played and best_game
  GAMES_PLAYED=$(echo "$USER_DATA" | cut -d '|' -f1)
  BEST_GAME=$(echo "$USER_DATA" | cut -d '|' -f2)

  # Print welcome back message with stats
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Start guessing process
echo "Guess the secret number between 1 and 1000:"

NUMBER_OF_GUESSES=0

while true; do
  read GUESS

  # Check if the input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment the number of guesses
  NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

  # Compare guess with secret number
  if [[ $GUESS -lt $SECRET_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    # Update the user's game data in the database
    # Increment the games played
    GAMES_PLAYED=$((GAMES_PLAYED + 1))
    # Check if the current game is the best game
    if [[ $BEST_GAME -eq 0 || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
      BEST_GAME=$NUMBER_OF_GUESSES
    fi
    # Update the database with new stats
    $PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME';"
    break
  fi
done
