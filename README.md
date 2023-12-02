# Distributed-Twitter-Engine-Erlang
This project is an Erlang-based simulation of basic Twitter functionalities, designed to mimic the client-server architecture of web services. It uses runtime memory for data management and focuses on efficient data storage and retrieval using Erlang maps.

# Features
- Simulates basic Twitter functionalities like tweeting, retweeting, and subscription management.
- Implements user registration, sign-in, and sign-out processes.
- Efficiently handles data using Erlang maps and persistent terms for quick access and modification.
- Capable of simulating up to 10k users, showcasing the efficiency of data handling.

# File Descriptions
- `Mainclass.erl`: Serves as the user interface and a buffer between the client and server.
- `Sendreceive.erl`: Manages tweets, including sending, receiving, and organizing them based on hashtags or users.
- `Register.erl`: Handles user-specific actions like registration and authentication.
- `Automation.erl`: Automates processes like registration and subscription for testing purposes.

# Installation and Running
1. Clone the repository to your local machine.
2. Replace `VenkatsaiROGG15` with your hostname in all files.
3. Compile the Erlang files:
    - `mainclass.erl`
    - `automation.erl`
    - `register.erl`
    - `sendreceive.erl`
4. Start the Erlang shell and run `mainclass:startTwitter()` to initialize the server.
5. For simulation, use `automation:startAutomation()` with specified user parameters.
6. For regular use, start with `mainclass:startTheRegistration()` to register and sign in users.

# Technology
- Erlang

# Performance Metrics
- Observes a sharp increase in time taken with the rising number of users and subscribers.
- Provides insights into the complexity of tweet distribution in large-scale simulations.
