# Work outside the code

Software controls are only one part of launching LuscentVist. Each section below needs an accountable owner and documented evidence.

## 1. Company and product decisions

- Form the operating entity and obtain appropriate insurance.
- Confirm initial distribution is U.S.-only and adult-oriented.
- Adopt the exact intended-use statement: personal organization and communication, not medical advice or clinical monitoring.
- Approve prohibited claims for marketing, support, partnerships, and app-store copy.
- Decide whether caregivers may enter another person's information and obtain legal guidance for that use.
- Recruit representative older adults, veterans, caregivers, and accessibility users for compensated usability research.

## 2. Legal and regulatory review

- Retain U.S. health-privacy counsel.
- Produce a written HIPAA covered-entity/business-associate analysis.
- Repeat the HIPAA analysis before any hospital, VA, insurer, employer, or provider agreement.
- Produce an FDA intended-use/classification memorandum.
- Assess FTC Act and Health Breach Notification Rule applicability.
- Assess California CMIA and California consumer privacy laws.
- Assess Washington My Health My Data and other state consumer-health laws.
- Build a state-by-state breach notification matrix.
- Confirm COPPA posture and adult-targeting controls.
- Review accessibility obligations.
- Review encryption export declarations for both app stores.
- Obtain written launch approval from counsel; disclaimers alone are not sufficient.

## 3. Required public documents

- General privacy policy
- Separate consumer health data privacy policy where required
- Terms of use
- Medical-purpose and emergency disclaimer
- User-facing data storage, export, and deletion explanation
- Vulnerability disclosure policy and `security.txt`
- Support policy instructing users not to email medical information
- Data retention and destruction schedule

## 4. GCP and vendor administration

- Register the company domain and create a Google Cloud Organization.
- Execute the Google Cloud BAA before any potentially regulated data enters GCP.
- Verify each selected service against Google's current BAA-covered product list.
- Use company identities, phishing-resistant MFA, group IAM, and two protected break-glass accounts.
- Establish development, staging, production, security, CI/CD, and disabled regulated-data projects.
- Review every SDK and vendor contract; maintain a vendor and subprocessor register.
- Do not assume all Firebase or marketplace products are covered by the GCP BAA.
- Establish billing ownership, budgets, quotas, and alerts.

## 5. App-store administration

- Enroll the company in Apple Developer Program and Google Play Console.
- Complete Apple App Privacy accurately, including every third-party SDK.
- Complete Google Data Safety and Health Apps declarations.
- Prepare age rating, category, support URL, privacy URL, screenshots, and reviewer notes.
- Establish signing-key custody and recovery procedures.
- Complete TestFlight and Google closed-testing requirements.
- Re-review declarations for every release that changes data handling.

## 6. Security program

- Name a security and privacy owner.
- Approve a risk assessment and mobile threat model.
- Establish least-privilege access reviews at least quarterly.
- Maintain an SBOM and dependency inventory.
- Define vulnerability remediation timelines by severity.
- Contract an independent mobile penetration test before public launch.
- Create incident response, evidence preservation, legal escalation, and consumer notification procedures.
- Run a breach tabletop exercise before launch and annually thereafter.
- Establish secure laptop, source-control, secret-management, and offboarding requirements.

## 7. Clinical and content governance

- Have a clinician review wording for accidental medical claims or misleading prompts.
- Maintain a review log for checklist templates and educational copy.
- Never introduce target ranges, dosage suggestions, medication interactions, or diagnostic language without a new regulatory assessment.
- Define how potentially dangerous user misunderstandings are reported and corrected.

## 8. Accessibility and usability

- Test with VoiceOver and TalkBack.
- Test large text, high contrast, reduced motion, switch control, and one-handed use.
- Test printed summaries with older adults and clinicians.
- Validate reading level and plain-language content.
- Provide accessible support channels.

## 9. Launch operations

- Define support ownership and response times.
- Train support staff never to request health records or screenshots containing them.
- Establish staged rollout, rollback, and emergency app-release procedures.
- Establish release evidence packets containing tests, approvals, SBOM, declarations, and privacy review.
- Monitor reviews and support messages for safety, privacy, and accessibility issues without collecting health analytics.

## 10. Future features

Cloud backup, provider integrations, HealthKit/Health Connect, device imports, and AI document explanation each require a new privacy impact assessment, threat model, legal review, store-declaration update, and explicit user consent design before implementation.
