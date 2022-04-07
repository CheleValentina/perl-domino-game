# perl-domino-game
A multiplayer Domino game written in Perl

Here are the rules of the game: 
  
- It's played by a minimum of 2 players and a max of 4 
- 28 domino pieces are laid upside down randomly 
- Each piece is divided in half and has two sets of dots in each half. Each set can have 0 to 6 dots. 
- Each player picks 7 pieces. 
- The player with the bigger double starts 
- After the first piece, they go in turns placing pieces that match the same number of dots. If they don't 
have one, they pick another piece from the table. 
- The game ends when a player runs out of pieces or there are no more pieces that match and no more 
pieces left on the table 
- If both players still have pieces in the end, the winner is the one with the least total dots. These are 
calculated by adding the dots from all the pieces in the player's hand.