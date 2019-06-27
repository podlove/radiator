# Data Model and Structure





## Content


- Network
	- Podcasts
		- Episodes



- User
	- identity (email/username/password_hash/other auhentication)




## Hierarchy of rights


* `:readonly` a `User` must have at least readonly rights to see the existence of an entry. This right is hierarchical. E.g. if Ariana has `:readonly` on a podcast, they can see both the Podcast as well as all the current published episodes. `:readonly` also allows a limited upside view. E.g. `:readonly` on an `Episode` gives access to public podcast metadata as well as the network.  

* `:edit` allows the user to edit metadata about a podcast

* `:manage` allows to edit public dates etc.

* `:own` - also allows to give access to others and hand over.


* Networks need at least one owner






