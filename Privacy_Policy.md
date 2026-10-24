# Privacy Policy for Calculator

**Effective Date:** October 24, 2026  
**Last Updated:** October 24, 2026  
**Application Name:** Calculator (Premium Calculator)  
**Package Name:** `com.dimension.calculator`  
**Contact Email:** [darkdotdarkline@gmail.com](mailto:darkdotdarkline@gmail.com)  

---

## Table of Contents
1. [Introduction and Overview](#1-introduction-and-overview)
2. [Legal Bases for Processing (GDPR / UK GDPR)](#2-legal-bases-for-processing-gdpr--uk-gdpr)
3. [Information We Collect](#3-information-we-collect)
   - [A. Data Processed and Stored Strictly Locally](#a-data-processed-and-stored-strictly-locally-on-your-device)
   - [B. Technical Telemetry and Device Data](#b-technical-telemetry-and-device-data-automatically-collected)
   - [C. Voluntary User Communications and Feedback](#c-voluntary-user-communications-and-feedback)
   - [D. Advertising and Third-Party SDK Data](#d-advertising-and-third-party-sdk-data)
4. [Device Permissions and Purpose](#4-device-permissions-and-purpose)
5. [Third-Party Services and Sub-processors](#5-third-party-services-and-sub-processors)
6. [Advertising and User Choices (Opt-Out Instructions)](#6-advertising-and-user-choices-opt-out-instructions)
7. [Google Play Data Safety Section Compliance](#7-google-play-data-safety-section-compliance)
8. [Data Retention and Storage Duration](#8-data-retention-and-storage-duration)
9. [User Rights and Data Deletion (GDPR, CCPA/CPRA, DPDP)](#9-user-rights-and-data-deletion-gdpr-ccpacpra-dpdp)
10. [Children's Privacy Protection (COPPA / GDPR-K)](#10-childrens-privacy-protection-coppa--gdpr-k)
11. [Data Security Measures](#11-data-security-measures)
12. [International Data Transfers](#12-international-data-transfers)
13. [California Consumer Privacy Rights (CCPA / CPRA Notice)](#13-california-consumer-privacy-rights-ccpa--cpra-notice)
14. [Changes to This Privacy Policy](#14-changes-to-this-privacy-policy)
15. [Contact Information and Grievance Redressal](#15-contact-information-and-grievance-redressal)

---

## 1. Introduction and Overview

Welcome to **Calculator** (referred to herein as **"the Application"**, **"the App"**, **"we"**, **"us"**, or **"our"**), operated under package name `com.dimension.calculator`. We respect your personal privacy and are dedicated to protecting any personal data collected through your use of the Application.

This Privacy Policy informs you about:
- What information we collect, why we collect it, and how it is used;
- The technologies and third-party partners involved in providing services;
- How your data is secured and your legal choices and rights regarding your information.

By downloading, installing, accessing, or using the Application, you acknowledge that you have read, understood, and consented to the data practices described in this Privacy Policy. If you do not agree with any aspect of this policy, please uninstall and discontinue using the Application immediately.

---

## 2. Legal Bases for Processing (GDPR / UK GDPR)

For users located within the European Economic Area (EEA), United Kingdom (UK), or Switzerland, our processing of your personal information is governed by the General Data Protection Regulation (GDPR) and UK Data Protection Act. We rely on the following lawful bases:

1. **Legitimate Interests (Article 6(1)(f) GDPR):** To ensure network and information security, prevent fraud and unauthorized device tampering, verify app compatibility, distribute remote app configuration, and improve application stability.
2. **Consent (Article 6(1)(a) GDPR):** Where required by applicable law, we request your affirmative consent prior to serving personalized advertisements via Google Mobile Ads or collecting voluntary feedback.
3. **Performance of a Contract (Article 6(1)(b) GDPR):** To provide you with core calculator calculation capabilities, history persistence, and user-selected interface customizations.
4. **Compliance with Legal Obligations (Article 6(1)(c) GDPR):** Where retention or disclosure is mandated by statutory or regulatory frameworks.

---

## 3. Information We Collect

### A. Data Processed and Stored Strictly Locally on Your Device
The core functionality of the Application operates locally on your hardware. We do **NOT** upload your private calculations to the cloud:
- **Calculation History and Expressions:** When you type math equations, trigonometric functions, or arithmetic operations, the equation strings, calculation outputs, and creation timestamps are written strictly to local on-device flash storage (`SharedPreferences`).
- **User Interface and Theme Configurations:** Color schemes, custom button settings, and display formatting choices remain strictly confined to your device.
- **Data Isolation:** This data is sandboxed within the Application's private storage directory. We do not transmit, analyze, or synchronize your calculation records to any remote server.
- **User Erasure:** You can permanently purge all stored calculation history at any moment by tapping the *"Clear History"* option within the app or by clearing data from Android Settings.

### B. Technical Telemetry and Device Data (Automatically Collected)
When the Application connects to our backend server (hosted via Supabase), it transmits limited technical heartbeat data:
- **Device Hardware Identifier:** A hardware identifier (e.g., Android ID or iOS Identifier for Vendor) utilized strictly to manage app installation status, identify test environments, and enforce anti-abuse / ban rules.
- **Hardware Profile:** Device manufacturer (e.g., Samsung, Xiaomi, Google), hardware model, screen metrics, and device type.
- **Operating System Data:** Android OS release version, build metadata, and system locale/language.
- **App Metadata:** Package name (`com.dimension.calculator`), internal build number, and semantic version string (e.g., `1.0.0`).
- **Network Metadata:** Coarse IP address (used temporarily during HTTP handshakes for routing and geographic server selection; not stored alongside user identities).

**Purpose of Processing:** This telemetry is used exclusively to:
- Deliver dynamic remote configuration (ad units, feature flags, menu button actions);
- Enforce security measures against reverse-engineering, app tampering, or unauthorized API access;
- Notify users of mandatory or recommended app version updates.

### C. Voluntary User Communications and Feedback
When you submit a support request, feedback message, or star rating through the in-app interface:
- **Submitted Content:** Text message of your comments, suggestions, or bug reports.
- **Rating Score:** Numerical rating (1 to 5 stars).
- **Association:** Transmitted alongside the anonymized device ID and timestamp to enable our development team to reproduce issues.
- **Purpose:** Used strictly for debugging, customer care, and quality enhancement.

### D. Advertising and Third-Party SDK Data
The Application incorporates third-party advertising SDKs (specifically **Google AdMob**) to support free access. When ads are requested or viewed, Google Mobile Ads may collect:
- **Advertising Identifiers:** Google Advertising ID (GAID / AAID) on Android devices, or Identifier for Advertisers (IDFA) on iOS.
- **Interaction Data:** Ad impressions, clicks, video completion rates, and viewability data.
- **Diagnostic Information:** Crash logs, app latency reports, and ANR (Application Not Responding) metrics.
- **General Location Data:** Non-precise, coarse geographic location derived from IP address (e.g., country or city level).

---

## 4. Device Permissions and Purpose

We strictly adhere to the principle of data minimization. The Application requests only the bare minimum permissions required for operation:

| Permission Name | Technical Descriptor | Stated Purpose |
| :--- | :--- | :--- |
| **Internet Access** | `android.permission.INTERNET` | Required to fetch remote configurations, retrieve AdMob advertisements, and transmit voluntary user feedback. |
| **Network State** | `android.permission.ACCESS_NETWORK_STATE` | Allows the App to verify whether an active Wi-Fi or cellular connection exists before attempting network calls, conserving battery and mobile data. |

### Permissions We Explicitly DO NOT Request:
- **No Location Tracking:** We do **not** request `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION`.
- **No Camera or Microphone:** We do **not** request `CAMERA` or `RECORD_AUDIO`.
- **No Contacts or Phone State:** We do **not** request `READ_CONTACTS`, `READ_PHONE_STATE`, or `GET_ACCOUNTS`.
- **No Shared Storage / Media:** We do **not** access user photos, documents, external storage, or personal files.

---

## 5. Third-Party Services and Sub-processors

To facilitate our services, we partner with reputable third-party infrastructure providers. Each partner operates under their own privacy protocols:

### 1. Google AdMob (Google LLC)
- **Service Type:** Mobile Advertising Network and Monetization.
- **Data Collected:** Advertising ID, IP address, device specs, ad interaction metrics.
- **Privacy Policies & Disclosures:**
  - [Google Privacy & Terms](https://policies.google.com/privacy)
  - [How Google uses information from sites or apps that use our services](https://policies.google.com/technologies/partner-sites)
  - [Google AdMob Data and Privacy Notice](https://support.google.com/admob/answer/6128543)

### 2. Supabase Inc.
- **Service Type:** Cloud Database and Backend API Infrastructure.
- **Data Collected:** Anonymous device hardware ID, OS version, device model, app version, feedback submissions.
- **Security:** End-to-end Transport Layer Security (TLS/HTTPS), encrypted databases at rest, row-level security (RLS).
- **Privacy Policy:** [Supabase Privacy Policy](https://supabase.com/privacy)

---

## 6. Advertising and User Choices (Opt-Out Instructions)

We support transparency and give you full control over how your advertising data is used:

### Personalized vs. Non-Personalized Ads
Depending on regional regulations (such as the EU User Consent Policy), you may receive targeted (personalized) or generic (non-personalized) ads. Non-personalized ads still use identifiers for frequency capping, aggregated ad reporting, and fraud detection.

### How to Reset or Delete Your Advertising ID
You can opt out of personalized ads or permanently reset your unique advertising identifier at any time:

- **On Android Devices (Android 12 and newer):**
  1. Open your phone's **Settings** app.
  2. Navigate to **Google** -> **All Services** (or search **Ads**).
  3. Tap **Ads**.
  4. Tap **Delete advertising ID** (or **Reset advertising ID**).  
     *Once deleted, apps will only see a string of zeros instead of your personal ad tracking identifier.*

- **On Older Android Devices (Android 11 and earlier):**
  1. Open **Settings** -> **Google** -> **Ads**.
  2. Toggle on **Opt out of Ads Personalization**.

- **On iOS Devices (if applicable):**
  1. Go to **Settings** -> **Privacy & Security** -> **Tracking**.
  2. Disable the toggle for **Allow Apps to Request to Track**.

---

## 7. Google Play Data Safety Section Compliance

For complete transparency with Google Play Store policies and requirements, here is the exact classification of our data handling practices:

| Data Category | Data Element | Collected | Shared with Third Parties | Ephemeral Processing | Encryption in Transit | Optional / Required |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Personal Info** | Name, Email, Address, Phone | **No** | **No** | N/A | Yes | N/A |
| **Financial Info** | Bank account, credit card, payment details | **No** | **No** | N/A | Yes | N/A |
| **User Content** | Math calculations, inputs, history | **Yes (Locally only)** | **No** | Stored locally | Stored on device | Required for core function |
| **Device Identifiers** | Android ID, Hardware Model, OS version | **Yes** | **Yes (Backend / AdMob)** | No (persisted for telemetry) | Yes (HTTPS / TLS) | Required for security & ads |
| **App Activity** | App interactions, ad clicks, ad views | **Yes** | **Yes (Google AdMob)** | No (aggregated analytics) | Yes (HTTPS / TLS) | Required for advertising |
| **App Info & Performance** | Diagnostics, crash logs, version strings | **Yes** | **Yes (Google AdMob / Supabase)** | No | Yes (HTTPS / TLS) | Required for stability |
| **User Feedback** | Feedback comments, star ratings | **Yes (Voluntary)** | **Yes (Stored in Supabase)** | No | Yes (HTTPS / TLS) | Optional (User initiated) |

- **Data Transfer Security:** All data in transit between the Application, Supabase, and Google AdMob is encrypted using standard industry-grade HTTPS/TLS 1.2 and TLS 1.3 protocols.
- **Data Deletion Mechanism:** Users can request immediate deletion of their telemetry records and feedback by emailing [darkdotdarkline@gmail.com](mailto:darkdotdarkline@gmail.com).

---

## 8. Data Retention and Storage Duration

- **Local Storage:** Calculation entries, history logs, and UI preferences remain on your device until you manually clear them or uninstall the Application.
- **Telemetry Records:** Telemetry logs stored in our backend (such as device model, OS version, and last heartbeat timestamp) are retained for operational verification and fraud prevention for up to twelve (12) months, after which they are automatically rotated or anonymized.
- **User Feedback Records:** Feedback entries are retained for up to twenty-four (24) months to facilitate software updates and product roadmap decisions, after which they are permanently deleted.

---

## 9. User Rights and Data Deletion (GDPR, CCPA/CPRA, DPDP)

Regardless of your geographic location, we respect your rights regarding your personal information:

1. **Right of Access:** You may request confirmation of whether we hold any technical data linked to your device identifier.
2. **Right to Rectification:** You can request that inaccurate or incomplete information be corrected.
3. **Right to Erasure ("Right to Be Forgotten"):** You have the right to request the total deletion of any device telemetry or feedback submitted from your device.
4. **Right to Restrict or Object to Processing:** You may object to the processing of your data on grounds relating to your particular situation.
5. **Right to Withdraw Consent:** Where processing is based on consent, you may withdraw your consent at any time without affecting the lawfulness of prior processing.

### How to Submit a Data Deletion Request
To exercise any of the rights listed above, please submit a written request to our dedicated privacy contact:
- **Email:** [darkdotdarkline@gmail.com](mailto:darkdotdarkline@gmail.com)
- **Subject Line:** *Privacy Rights / Data Deletion Request - Calculator App*
- **Verification:** Please include your anonymous Device ID (visible in the App's About/Settings screen, if applicable) or device model to help us locate and purge any corresponding records within thirty (30) days.

---

## 10. Children's Privacy Protection (COPPA / GDPR-K)

The Application is designed as a general-utility calculation tool. We do not intentionally target, solicit, or collect personal information from children under the age of 13 (or under 16 for residents of the European Union).

Because our calculation operations occur locally on the user's device and do not require user accounts, email registration, or age verification, we do not intentionally assemble personal profiles of child users. Furthermore, third-party advertising SDKs are configured to comply with Google Play's Families Policy and COPPA requirements.

If you are a parent or legal guardian and believe that your child has provided personal information to our servers without your verifiable consent, please contact us immediately at [darkdotdarkline@gmail.com](mailto:darkdotdarkline@gmail.com). Upon notification, we will take prompt steps to verify and delete such information from our records.

---

## 11. Data Security Measures

We take technical and organizational security measures seriously:
- **Transport Security:** All client-to-server traffic is forced over HTTPS utilizing TLS 1.2 / TLS 1.3 encryption to protect data against eavesdropping, interception, or man-in-the-middle attacks.
- **Storage Protection:** In-app data is shielded by Android's application sandboxing architecture, ensuring other installed applications cannot read your calculation history without root access.
- **Access Control:** Access to backend databases (Supabase) is strictly restricted by Row Level Security (RLS) policies and authorized developer API credentials.
- **No Sensitive Credential Storage:** The Application does not request, handle, or store credit card numbers, passwords, or government identification numbers.

While we implement industry-standard safeguards, please understand that no method of transmission over the Internet or electronic storage can be guaranteed to be 100% invulnerable.

---

## 12. International Data Transfers

Our third-party cloud infrastructure (Supabase, Google) maintains servers located in the United States and globally distributed data centers. If you access the Application from outside the United States, your technical telemetry and advertising identifiers may be transferred to, stored, and processed in jurisdictions where data protection laws may differ from those in your country.

Where transfers occur from the EEA, UK, or Switzerland to countries without an adequacy decision, our partners rely on European Commission-approved Standard Contractual Clauses (SCCs) to ensure an adequate level of data protection.

---

## 13. California Consumer Privacy Rights (CCPA / CPRA Notice)

If you are a California resident, the California Consumer Privacy Act (CCPA) as amended by the California Privacy Rights Act (CPRA) affords you additional privacy rights:

- **Categories of Information Collected:** Identifiers (device hardware ID, advertising ID), Internet/network activity (ad interaction).
- **No Sale of Personal Information:** We do **NOT** sell your personal data for monetary consideration.
- **Sharing for Cross-Context Behavioral Advertising:** We allow third-party advertising networks (Google AdMob) to collect advertising identifiers to deliver relevant ads. You may opt out of this sharing via your Android settings as detailed in [Section 6](#6-advertising-and-user-choices-opt-out-instructions).
- **Right to Non-Discrimination:** We will not deny you goods or services, charge different prices, or provide a different level of quality if you exercise your CCPA rights.
- **Shine the Light Law:** California Civil Code Section 1798.83 permits California residents to request details regarding disclosure of personal data to third parties for direct marketing. We do not disclose personal information to third parties for their own direct marketing purposes.

---

## 14. Changes to This Privacy Policy

We may update this Privacy Policy periodically to reflect enhancements to our Application, changes in legal statutes, or modifications to our third-party integrations.

When changes are made:
- We will revise the **"Last Updated"** date at the very top of this document.
- In the event of material changes that affect your rights or our collection practices, we may provide prominent in-app notification alerts or dialogs prior to the implementation of the change.
- Your continued use of the Application following the publication of any revised Privacy Policy signifies your explicit acceptance of the updated terms.

---

## 15. Contact Information and Grievance Redressal

If you have any questions, clarifications, complaints, data deletion inquiries, or feedback regarding this Privacy Policy and our privacy practices, please contact us directly:

- **Entity / Developer:** Calculator Support Team
- **Dedicated Privacy Email:** [darkdotdarkline@gmail.com](mailto:darkdotdarkline@gmail.com)
- **Application Package:** `com.dimension.calculator`
- **Response Commitment:** We aim to review and respond to all legitimate privacy inquiries within fifteen (15) to thirty (30) business days.
