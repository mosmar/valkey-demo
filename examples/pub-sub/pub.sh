# In terminal 2
valkey-cli publish my-channel "Hello"
valkey-cli publish my-channel 'Who goes there?!'

# 1) The first element is the type of message. For a successful subscription, this will be the string subscribe.
# 2) The second element is the name of the channel to which the client successfully subscribed.
# 3) The third element is an integer representing the total number of channels and patterns the client is currently subscribed to.