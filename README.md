```markdown
<!--
  README.md for “Automated VM Backup & Replication”
-->

## 📖 Summary  
In modern IT environments, unplanned VM failures and ransomware attacks can halt business operations and cause catastrophic data loss; this project implements a fully automated, incremental, encrypted VM backup pipeline to AWS S3—ensuring off-site durability, security, and compliance.  

## 🏭 Real-World Problem  
Enterprises face relentless ransomware attacks that target backups to cripple recovery—93% of cyber-attacks now aim at backup storage, and 75% succeed in disabling recovery capabilities without immutable, encrypted off-site copies  ([New Veeam Research Finds 93% of Cyber Attacks Target Backup ...](https://www.veeam.com/company/press-release/new-veeam-research-finds-93-percent-of-cyber-attacks-target-backup-storage-to-force-ransom-payment.html?utm_source=chatgpt.com)). Traditional full-snapshot methods are slow, storage-hungry, and often lack robust encryption or air-gapping, leaving critical workloads exposed  ([Ransomware Statistics, Data, Trends, and Facts [updated 2024]](https://www.varonis.com/blog/ransomware-statistics?utm_source=chatgpt.com)).

## 💡 Proposed Solution  
1. **Incremental backups** via GNU tar’s `--listed-incremental` so only changed files are archived, minimizing backup windows and S3 storage costs  ([GNU tar 1.35: 5 Performing Backups and Restoring Files](https://www.gnu.org/software/tar/manual/html_chapter/Backups.html?utm_source=chatgpt.com)).  
2. **AES-256 symmetric encryption** with GPG on each archive before upload, protecting data at rest under a passphrase you manage  ([Using GPG to Encrypt Your Data - HECC Knowledge Base](https://www.nas.nasa.gov/hecc/support/kb/using-gpg-to-encrypt-your-data_242.html?utm_source=chatgpt.com)).  
3. **Secure transfer** to S3 over TLS—AWS CLI uses SSL by default—ensuring data-in-transit confidentiality  ([Does AWS CLI use SSL when uploading data into S3?](https://stackoverflow.com/questions/34654728/does-aws-cli-use-ssl-when-uploading-data-into-s3?utm_source=chatgpt.com)).  
4. **Locking** with `flock` in Bash to prevent overlapping runs, guaranteeing one consistent backup at a time  ([Understanding the Use of `flock` in Linux Cron Jobs - DEV Community](https://dev.to/mochafreddo/understanding-the-use-of-flock-in-linux-cron-jobs-preventing-concurrent-script-execution-3c5h?utm_source=chatgpt.com)).  
5. **Least-privilege IAM** policy granting only `s3:PutObject`, `GetObject`, `ListBucket`, `DeleteObject` on your backup bucket  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com)).  
6. **Log rotation** of both backup archives and logs to enforce retention and control costs.

## ✅ Why This Solution  
- **Efficiency:** Incremental tar dumps only deltas, shrinking backup windows and S3 usage  ([How to create incremental and differential backups with tar](https://linuxconfig.org/how-to-create-incremental-and-differential-backups-with-tar?utm_source=chatgpt.com)).  
- **Security:** Client-side GPG encryption plus enforced HTTPS ensures confidentiality and integrity  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com)).  
- **Reliability:** Cron + `flock` prevents job overlap or “thundering herd” issues  ([using flock with cron - linux - Server Fault](https://serverfault.com/questions/748943/using-flock-with-cron?utm_source=chatgpt.com)).  
- **Compliance:** Centralized logs, rotation, and least-privilege IAM meet audit standards  ([Protecting data with encryption - Amazon Simple Storage Service](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html?utm_source=chatgpt.com)).

## 🏗 Architecture Overview  
```
[VM Data] 
   └─> tar --listed-incremental=snar.state → gzip → GPG encrypt → aws s3 cp → S3 bucket (versioned)
                                   ↓                          ↑
                           snar.state file             IAM role with least-privilege
                                   ↓
                       Rotate old backups & logs
```

## 🛠 Tech Stack  
- **Bash** (`set -euo pipefail`) for robust scripting  
- **GNU tar** with `--listed-incremental` for delta dumps  ([GNU tar 1.35: 5 Performing Backups and Restoring Files](https://www.gnu.org/software/tar/manual/html_chapter/Backups.html?utm_source=chatgpt.com))  
- **GPG** AES256 symmetric encryption  ([Using GPG to Encrypt Your Data - HECC Knowledge Base](https://www.nas.nasa.gov/hecc/support/kb/using-gpg-to-encrypt-your-data_242.html?utm_source=chatgpt.com))  
- **AWS CLI v2** for S3 interactions  
- **cron + flock** to schedule and lock jobs  ([Understanding the Use of `flock` in Linux Cron Jobs - DEV Community](https://dev.to/mochafreddo/understanding-the-use-of-flock-in-linux-cron-jobs-preventing-concurrent-script-execution-3c5h?utm_source=chatgpt.com))  
- **AWS IAM** least-privilege policies  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com))  
- **Log rotation** via custom script

## 📋 Prerequisites  
- Linux host with Bash ≥4.0, GNU tar, GPG, AWS CLI v2  
- S3 bucket with versioning & TLS-only policy enabled  ([Enforcing encryption in transit with TLS1.2 or higher with Amazon S3](https://aws.amazon.com/blogs/storage/enforcing-encryption-in-transit-with-tls1-2-or-higher-with-amazon-s3/?utm_source=chatgpt.com))  
- IAM role or user with programmatic access and least-privilege S3 policy  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com))  
- `cron`, `flock` utilities  

## 🚀 Installation  
1. **Clone repo**  
   ```bash
   git clone https://github.com/you/vm-backup.git
   cd vm-backup
   ```  
2. **Make scripts executable**  
   ```bash
   chmod +x bin/*.sh scripts/*.sh
   ```  
3. **Configure**  
   - Copy and edit `config/backup.conf` with your directories, S3 bucket, region, and GPG passphrase path.  
   - Secure passphrase file:  
     ```bash
     cp config/passphrase.txt /etc/vm-backup/passphrase.txt
     chmod 600 /etc/vm-backup/passphrase.txt
     ```

## ⚙️ Configuration (`config/backup.conf`)  
```ini
BACKUP_DIR=/var/backups/vm
TMP_DIR=/tmp/vm-backup
LOG_DIR=/var/log/vm-backup
SNAR_FILE=$BACKUP_DIR/snar.state

S3_BUCKET=my-vm-backups
S3_REGION=us-east-1

GPG_PASSPHRASE_FILE=/etc/vm-backup/passphrase.txt

LOG_RETENTION_DAYS=30
BACKUP_RETENTION_DAYS=7
```

## ▶️ Usage  
Test a manual run:  
```bash
bin/backup.sh
```  
This will lock via `/var/lock/vm-backup.lock`, create an incremental tar.gz, encrypt to `.gpg`, upload to S3, then rotate old files. Logs land in `$LOG_DIR/backup_YYYY-MM-DD.log`.

## ⏰ Scheduling with Cron  
Edit the `vmbackupuser` crontab (`crontab -u vmbackupuser -e`):  
```cron
0 2 * * * /usr/bin/flock -n /var/lock/vm-backup.lock /usr/local/bin/backup.sh >> /var/log/vm-backup/cron.log 2>&1
```
Runs daily at 02:00 AM without overlap  ([How to prevent duplicate cron jobs from running? - Better Stack](https://betterstack.com/community/questions/how-to-prevent-duplicate-cron-jobs-from-running/?utm_source=chatgpt.com)).

## 📊 Logging & Monitoring  
- **Logs** in `$LOG_DIR`, rotated by `scripts/rotate_logs.sh`.  
- **CloudWatch** alarms on S3 errors or KMS events  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com)).  
- **SNS** or email alerts can wrap `bin/backup.sh`.

## 🔒 Security Considerations  
- Enforce **HTTPS-only** S3 access (`aws:SecureTransport`)  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com)).  
- Consider S3 Object Lock (WORM) for immutable retention  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com)).  
- Use AWS KMS CMK for server-side encryption if needed  ([Protecting data with encryption - Amazon Simple Storage Service](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingEncryption.html?utm_source=chatgpt.com)).  

## 🛠 IAM Policy Example (`iam/s3-least-privilege-policy.json`)  
```json
{
  "Version":"2012-10-17",
  "Statement":[{
    "Effect":"Allow",
    "Action":["s3:PutObject","s3:GetObject","s3:ListBucket","s3:DeleteObject"],
    "Resource":["arn:aws:s3:::my-vm-backups","arn:aws:s3:::my-vm-backups/*"]
  }]
}
```

## 🐞 Troubleshooting  
- **Lock contention?** Remove stale `/var/lock/vm-backup.lock`  ([using flock with cron - linux - Server Fault](https://serverfault.com/questions/748943/using-flock-with-cron?utm_source=chatgpt.com)).  
- **Upload failures?** Validate AWS credentials/role and network (TLS)  ([Does AWS CLI use SSL when uploading data into S3?](https://stackoverflow.com/questions/34654728/does-aws-cli-use-ssl-when-uploading-data-into-s3?utm_source=chatgpt.com)).  
- **GPG errors?** Check passphrase file path and permissions  ([Using GPG to Encrypt Your Data - HECC Knowledge Base](https://www.nas.nasa.gov/hecc/support/kb/using-gpg-to-encrypt-your-data_242.html?utm_source=chatgpt.com)).

## 🤝 Contributing  
1. Fork the repo  
2. Create a feature branch  
3. Ensure all scripts pass ShellCheck CI  ([Security best practices for Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html?utm_source=chatgpt.com))  
4. Submit a PR  

## 📄 License  
This project is licensed under the MIT License.  
```