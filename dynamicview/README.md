# Dynamic view

CREATE VIEW doesn't work when I want the view to select a dynamic fieldname (like language) from table.

So instead of CREATE VIEW, going to try to use a function to return a formatted string, to be executed.

## status: works!

Only use this if the view (now a function) is going to be used more than once.

