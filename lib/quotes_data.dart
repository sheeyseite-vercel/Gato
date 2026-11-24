// Built-in texts: mood messages, cat words, writing prompts, quote greetings.
const moodMessages = <String, List<String>>{
  'great': [
    'That glow looks good on you. Ride it all the way today.',
    'Great days are made of small wins. Collect a few more.',
    'Your energy is contagious. Share a little of it with someone.',
    'Remember this feeling. It\'s proof that good days happen.',
    'Love that for you. Go make the most of it.',
  ],
  'good': [
    'Steady and good is a beautiful place to be.',
    'A good day is a quiet kind of win. Enjoy it.',
    'Keep going at your pace. It\'s working.',
    'Good is plenty. Add one small thing you\'ll be proud of.',
    'Nice. A little kindness to yourself will make it even better.',
  ],
  'okay': [
    'Okay is allowed. Not every day has to sparkle.',
    'Plain days build strong foundations. One small step is enough.',
    'Take it one hour at a time. You\'re doing fine.',
    'Even a so-so day can end with something good. Look for it.',
    'Be gentle with the middle of the road. Tomorrow is a fresh page.',
  ],
  'tired': [
    'Rest isn\'t quitting. Give yourself permission to slow down.',
    'You\'ve carried a lot. A glass of water, a deep breath, then the next small thing.',
    'Tired means you tried. Be kind to yourself tonight.',
    'Lower the bar today and still count it as a win.',
    'This feeling passes. Sleep is a superpower, so use it.',
  ],
};

/// 24 distinct words: a word only comes back after 23 other cards.
const catWords = <String>[
  'Meoo', 'Mrrp', 'Purr', 'Nyaa', 'Mew', 'Prrr', 'Meow', 'Mrow',
  'Miau', 'Mraow', 'Meep', 'Mrr?', 'Nya~', 'Mew mew', 'Purrr', 'Mrrow',
  'Mao', 'Prrp', 'Meeow', 'Nyan', 'Mrrrp', 'Brrp', 'Mew?', 'Meow!',
];

const prompts = <String>[
  'What made you smile today?',
  "What's one thing you're grateful for right now?",
  'Describe today in three words.',
  'What did you learn this week?',
  'Who made your day a little easier?',
  "What would you tell yesterday's you?",
  "What's on your mind that you haven't said out loud?",
  'What small win can you celebrate?',
  'What are you looking forward to?',
  'What would a perfect ordinary day look like?',
  'What do you need more of this week?',
  'What drained you today, and what refilled you?',
  'Write about a place that feels like home.',
  'What are you proud of lately?',
  "What's one thing you'd like to let go of?",
  'Describe a sound you love.',
  'What did you notice today that you usually miss?',
  'Who do you want to thank?',
  'What goal can you shrink into one small step?',
  'What does rest look like for you?',
  'What is a kind thing you did recently?',
  'What would you do if you weren\'t afraid?',
  'What song matches your mood today?',
  'What do you want to remember about this season?',
];

const quoteGreetings = <String>[
  "What's new?",
  'Heard any good words lately?',
  'Got a line worth keeping?',
  'Anything catch your ear today?',
  'What are we saving today?',
  'Found something worth quoting?',
];
