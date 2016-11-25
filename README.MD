# ioc
Slow approach to Ionversion of Control in D2 language

# Features

## Package scan

Add execution of generate_index.d with rdmd to your DUB file's preGenerateCommands to trigger building an index of modules.
You can later inspect that and browse module tree - see ioc.scan unittest.

I'd propose adding **/_index.d to .gitignore.
