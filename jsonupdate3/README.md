# JSON update CROSS-TABLE

Builds on jsonupdate2.

See "viewupdate" directory for another approach.

I think I like this one better, though maybe there's a hybrid.

Doing it this way probably means making an update_blah(id, json) function for every table I want to have updated via JSON.  So, a little extra boilerplate, but not such a bad thing in return for the simplicity of being able to have API just pass through JSON for updates.

# status: works great!

