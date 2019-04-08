## Submission Guidelines

## <a name="commit"></a> Git Commit Guidelines

We have some loose rules over how our git commit messages on the mainline should be formatted. This is supposed to lead to **more readable messages** that are easy to follow when looking through the **project history**.  But also, we can use the git commit messages to **generate the change log** for releases.

### Commit Message Format
Each commit message consists of a **header**, a **body** and a **footer**.  

The header has a special format that includes a **type**, a **area** and a **subject**:

```
<type>(<area>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The **header** is mandatory and the **scope** of the header is optional.

### Type
Should be one of the following:

* **add**: A new feature
* **fix**: A bug fix - in this case the footer should contain at least one "fixes #<>" line
* **doc**: Documentation only changes
* **format**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
* **refactor**: A code change that neither fixes a bug nor adds a feature
* **perf**: A code change that improves performance
* **test**: Adding missing or correcting existing tests
* **chore**: Changes to the build process or auxiliary tools and libraries such as documentation generation

### Area
The area could be one of the area:<name> tags we have in the github issue system. E.g. `auth`, `content`, `perm`, etc. If more than one should be comma separated.  

### Subject
The subject contains succinct description of the change:

* use the imperative, present tense: "change" not "changed" nor "changes"
* don't capitalize first letter
* no dot (.) at the end

### Body
Just as in the **subject**, use the imperative, present tense: "change" not "changed" nor "changes". The body can include additional information, reference to other issues, or a list of multiple header lines if this is a bigger squash commit

### Footer
The footer shoul contain one line for each github issue it closes.
If the commit contains**Breaking Changes**, the description of them should start with the word `BREAKING CHANGE: `. The rest of the footer can be freely formatted to repesent it.

### Revert
If the commit reverts a previous commit, it should begin with `revert: `, followed by the header of the reverted commit.
In the body it should say: `This reverts commit <hash>.`, where the hash is the SHA of the commit being reverted.

