---
name: submit
description: Submit the work in this session so it gets independent advice before it goes into the app. Use when someone says submit, send this for checking, or I am done with this change.
---

The person may not be a developer. Use plain words, one step at a time, and never make them type git commands. Do all the steps yourself.

1. **Ask what the change is for.** Ask one plain question: "In a sentence, what should this change do?" Use their words as the pull request description.

2. **Protect the real branch.** If on `main`, create a branch named `change/<short-description>`. Never push to `main`. Never merge anything, and never force-push, unless the person asks and the warning in step 6 has been shown.

3. **Do not send secrets or real data.** Look at what would be committed. Do not include `.env` files or anything with a password, key or real customer details. If you find one, stop and tell the person, without showing its value.

4. **Check who else is here.** Before pushing:
   - List open pull requests with `gh pr list --json number,title,author,files,headRefName`. Compare their files with this change.
   - For each changed file, find who last changed it: `gh api "repos/{owner}/{repo}/commits?path=<file>&per_page=1"`. Use the GitHub login. If it is a bot or Claude, say so rather than treating it as a person.
   - If another pull request touches the same files, tell the person: "A similar change was submitted by X (or by your other session, on branch Y). It touches these files: ... Do you want to overwrite that work, or remove this part from yours?" Ask, and wait for the answer. Record the question and the answer in the pull request description, under "Overlap decision". This only compares files, so say it cannot catch two changes that clash in other ways.
   - If there is no overlap, say who last changed the files, in one line.

5. **Submit.** Commit, push the branch and open a pull request with `gh pr create`, using their sentence. Tell them: "Submitted. The check usually takes a few minutes."

6. **Show the feedback.** Wait for the comment using `gh pr view <number> --json comments`, checking about every 30 seconds for up to 10 minutes, then show it to the person word for word. If nothing arrives, say so plainly: "The check has not answered. This is not your fault." Do not write your own verdict on top, and do not soften or remove findings.

7. **Next step.** Ask what they want to do.
   - If they paste or accept the fixes, make them, then submit again on the same branch.
   - Do not change a test's expected value to make a problem go away, unless the person understands that is what is happening and the reason is written in the pull request.
   - If they want it merged, tell them first: "This is advice only. Nothing here proves the change is safe. Merging changes the nightly data jobs straight away." Then follow the team's process. Never run a deploy.

If two attempts to fix the same thing fail, stop and tell them to ask the team lead.
