# Test and verification checks

Use this when a change adds behavior, changes behavior, or fixes a bug.

Check:

- the test exercises the changed behavior, not just implementation details;
- failure paths and edge cases are covered when relevant;
- snapshots or broad mocks do not hide the real behavior;
- the reported verification command matches the project type;
- skipped tests or missing verification are called out as risks.
