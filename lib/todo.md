
** the width property in the node object always extends to the max_level because for simplicity
we didn't want fetching a non-filled in value to be nil (better to be 0).  Look into maybe
encapsulating this a bit.  Is there a default return value for arrays we can alter for this?
change the API?  (width is basically never asked for without indexing into it)
