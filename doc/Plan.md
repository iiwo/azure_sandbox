# Azure Excel Compatibility Lab – End-to-End Plan
## Objective
Run **short-lived Windows environments** in Azure to test **Excel 2016 / 2019 / 2021 compatibility**, using **unactivated Excel**, while paying only for **minutes of compute time**.
This setup is designed to be:
* Cost-efficient
* Deterministic
* Disposable
* Licensing-safe for evaluation/testing
---
## High-Level Strategy
* Use **Azure Spot Windows VMs** (cheap, interruptible instances)
* Install **Excel via Office Deployment Tool (ODT)**
* Run Excel in **evaluation (unactivated) mode**
* Test briefly (minutes to hours)
* **Delete the VM immediately after testing**
---
## Phase 1 — Azure Account (one-time)
1. Create an Azure account.
2. Activate the **$200 / 30-day free trial** credit.
3. Immediately configure your subscription:
4. Set up spending/budget alerts (e.g. at 50%, 75%, 90% of credit usage)
5. Enable default VM **auto-shutdown** (schedule to turn off VMs after 1–2 hours by default)
**Outcome:** Avoid surprise costs by using free credits first and auto-stopping VMs.
---
## Phase 2 — Tooling (one-time)
1. Download the **Office Deployment Tool (ODT)** from Microsoft and install it.
2. Prepare **reusable configuration XML** files for each required Excel version:
3. Excel 2016
4. Excel 2019
5. Excel 2021
Each config should be tailored to:
* Install **Excel only** (no other Office apps)
* **Disable automatic updates** (to keep the installation consistent)
* Avoid activation prompts (use volume license mode for a built-in grace period)
For example, a configuration file for *Excel 2019* (volume license) might look like:
```xml
<Configuration>
  <Add OfficeClientEdition="64" Channel="PerpetualVL2019">
    <Product ID="ProPlus2019Volume" PIDKEY="#####-#####-#####-#####-#####">
      <Language ID="en-us" />
      <ExcludeApp ID="Access" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="OneNote" />
      <ExcludeApp ID="Outlook" />
      <ExcludeApp ID="PowerPoint" />
      <ExcludeApp ID="Publisher" />
      <ExcludeApp ID="Teams" />
      <ExcludeApp ID="Word" />
    </Product>
  </Add>
  <Updates Enabled="FALSE" />
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
```
*(In the above, all Office apps except Excel are excluded. The PIDKEY can be left blank or set to a generic volume license key if needed. Using the volume license product ensures Excel will run in evaluation mode with a grace period instead of requiring immediate activation.)*
**Outcome:** Deterministic, one-click Excel installers for each version that can be reused indefinitely.
---
## Phase 3 — Test Session Workflow (repeatable for each test)
For **each compatibility test session**:
1. **Create an Azure Spot VM** for the test environment:
2. **OS:** Windows 10 Pro or Windows 11 Pro (latest available image)
3. **VM Size:** Use a small instance like Standard\_B2s or Standard\_D2s\_v3
4. **Pricing:** Enable *Spot* pricing (to get unused capacity at deep discounts)
5. **Eviction policy:** Choose *Delete* on eviction to avoid storage costs if Azure reclaims the VM.
6. Boot the VM and connect to it via Remote Desktop (RDP).
7. On the VM, run the Office Deployment Tool with the desired Excel version’s configuration:
8. Transfer or download your prepared XML config and the ODT setup.exe onto the VM.
9. **Install Excel:** Open a command prompt (or PowerShell) in the ODT folder and execute the installer. For example:
* setup.exe /configure Excel2019\_Config.xml
* (This will download and install Excel 2019 according to the configuration, without user intervention.)
10. Launch Excel on the VM. It will run in **unactivated evaluation mode** (no sign-in or product key needed). You can ignore any activation prompts – the product will be fully functional during the short test period.
11. Perform your compatibility testing on the Excel version (keep usage under 24 hours – typically just minutes). Save any required results externally, since the VM will be transient.
12. **Delete the VM** (and its associated disks) **immediately after testing**. You can do this from the Azure portal or via CLI (e.g. az vm delete ...). This ensures you stop incurring any charges.
**Outcome:** A fresh Excel environment for every test, minimal cost (only minutes of compute time), and no persistent data or licensing footprint left behind.
---
## Phase 4 — Cost & Licensing Model
* **Pay-per-use:** Azure charges you only for the VM’s active time. Using Spot VMs further minimizes cost (Spot instances can be up to \~90% cheaper than normal on-demand VMs).
* **Short-term Office usage:** Installing Excel in evaluation mode provides a built-in grace period (\~30 days for volume-licensed editions) before requiring activation. This is more than sufficient for a testing session of a few hours or days.
* **No Office license needed:** Because each test VM is deleted within the grace period and Excel was never activated, you do not consume or require any perpetual or subscription license. This approach leverages Microsoft’s trial/evaluation allowances legitimately.
* **Ephemeral state:** Deleting the VM wipes out the installed software and any cached license state. Each test starts clean, avoiding “version drift” or activation accumulation.
**Mental model:** *The VM is disposable hardware; Excel is a temporary evaluation install.* In essence, you’re renting a PC and a trial copy of Excel for just as long as you need them, then returning both.
---
## Phase 5 — Optional Optimization (if tests become frequent)
If you begin running these tests regularly and want to save setup time:
1. Create one **template VM** for each Excel version (e.g., one with Excel 2016 installed, another with Excel 2019, etc.).
2. Install the respective Excel version on each template VM once using the above process. Do not activate Excel (leave it in evaluation mode).
3. Shut down the template VM and capture it as a **Custom Image** in Azure. This image preserves the OS and the installed Excel.
4. For future tests, **spawn new Spot VMs from the custom image** instead of installing from scratch. The new VM will already have Excel installed (still unactivated). You can directly start testing, then delete the VM when done.
This trades a bit of upfront effort in image creation for faster repeat test deployments. **Note:** You should periodically refresh these images or re-install Excel if the grace period for activation ever lapses on the image. (Each new VM from the image will have its own trial timer starting at first boot or first Excel launch.)
---
## What This Setup Intentionally Avoids
* Long-running or persistent VMs (which incur ongoing costs even when idle)
* Windows 365 or other subscription VDI services (high recurring fees for always-available machines)
* Microsoft 365 (Office 365\) user licensing or sign-ins for the test machines
* Paying for Office licenses per VM or per user for these tests
* The risk of version drift or software updates – each session starts with a clean, known state
* Any kind of production or confidential data on the test machine (the VM is purged after use)
*(In short, the solution avoids any component that would introduce significant cost, complexity, or long-term maintenance.)*
---
## Critical Rule (Do Not Break)
**Every test VM is disposable. No VM persists beyond the test session.**
Breaking this rule (for example, by keeping a VM running or reusing a VM without rebuilding) undermines the entire model. Adhering to disposability guarantees:
* **Low cost:** You’re never paying for idle time or more than a few hours of compute.
* **Clean licensing posture:** Every session uses Microsoft’s allowed trial period, and no long-term unlicensed use occurs.
* **Reproducible results:** Each test starts in a fresh environment, so you eliminate variability caused by leftover files, settings, or updates.
---
## One-Sentence Summary
**Azure Spot VM → install Excel (unactivated) → test → delete. Repeat for each required Excel version.**
---
## Appendix: Reference Links
* **Azure Free Trial and Credits** – *Avoid charges with your Azure free account (Microsoft Learn)* – https://learn.microsoft.com/en-us/azure/cost-management-billing/manage/avoid-charges-free-account
* **Azure Budget Alerts** – *Best practices for optimizing cost in Azure (Microsoft Q\&A)* – https://learn.microsoft.com/en-us/answers/questions/2191846/what-are-the-best-practices-for-optimizing-cost-in
* **Azure VM Auto-Shutdown Feature** – *Announcing auto-shutdown for VMs using Azure Resource Manager (Azure Blog)* – https://azure.microsoft.com/en-us/blog/announcing-auto-shutdown-for-vms-using-azure-resource-manager/
* **Azure Spot VM Overview** – *Azure Spot VMs: A Practical Guide with Use Cases and Best Practices (Intercept Cloud Blog)* – https://intercept.cloud/en-gb/blogs/azure-spot-virtual-machines
* **Office Deployment Tool Download** – *Office Deployment Tool (Microsoft Download Center)* – https://www.microsoft.com/en-sa/download/details.aspx?id=49117
* **Office Deployment Config Options** – *Product IDs supported by the Office Deployment Tool (Microsoft Learn)* – https://learn.microsoft.com/en-us/troubleshoot/microsoft-365-apps/office-suite-issues/product-ids-supported-office-deployment-click-to-run
* **Office KMS Activation Grace Period** – *Guidelines for troubleshooting the Key Management Service – KMS (Microsoft Learn)* – https://learn.microsoft.com/en-us/windows-server/get-started/activation-troubleshoot-kms-general
---
