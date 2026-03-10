import smtplib
from email.message import EmailMessage
import os
import configparser
from typing import Dict, Optional


def read_config_file(config_path: str = "email_config.ini") -> Optional[Dict]:
    """
    Read email configuration from INI config file
    """
    try:
        config = configparser.ConfigParser()
        config.read(config_path)

        config_dict = {
            "smtp": dict(config["SMTP"]) if "SMTP" in config else {},
            "email": dict(config["EMAIL"]) if "EMAIL" in config else {},
            "recipients": [],
            "attachments": [],
        }

        # Parse recipients
        if "RECIPIENTS" in config:
            recipients_section = config["RECIPIENTS"]
            config_dict["recipients"] = [
                email.strip()
                for email in recipients_section.get("emails", "").split(",")
                if email.strip()
            ]

        # Parse attachments
        if "ATTACHMENT" in config:
            attachment_section = config["ATTACHMENT"]
            for key in attachment_section:
                value = attachment_section.get(key)
                if value:
                    config_dict["attachments"].append(value.strip())

        return config_dict

    except FileNotFoundError:
        print(f"Configuration file not found: {config_path}")
        return None
    except Exception as e:
        print(f"Error reading configuration file: {e}")
        return None


def send_email_from_config(config_path: str = "email_config.ini") -> bool:
    """
    Send email using configuration from config file
    """
    config = read_config_file(config_path)

    if not config:
        print("Failed to read configuration file")
        return False

    # SMTP Settings
    smtp = config["smtp"]
    smtp_server = smtp.get("server", "smtp.gmail.com")
    smtp_port = int(smtp.get("port", "587"))
    smtp_user = smtp.get("username", "")
    smtp_pass = smtp.get("password", "")

    # Email metadata
    email_config = config["email"]
    email_from = email_config.get("from", smtp_user)
    subject = email_config.get("subject", "Build Notification")
    body = email_config.get("body", "Build completed successfully.")

    # Recipients
    recipients = config["recipients"]
    if not recipients:
        recipients = [email_config.get("to", "")]

    attachments = config["attachments"]

    print(f"SMTP Server: {smtp_server}:{smtp_port}")
    print(f"From: {email_from}")
    print(f"Recipients: {recipients}")
    print(f"Subject: {subject}")

    try:
        msg = EmailMessage()
        msg["From"] = email_from
        msg["To"] = ", ".join(recipients)
        msg["Subject"] = subject
        msg.set_content(body)

        # Add attachments
        for path in attachments:
            if os.path.exists(path):
                with open(path, "rb") as f:
                    data = f.read()
                    filename = os.path.basename(path)
                msg.add_attachment(
                    data,
                    maintype="application",
                    subtype="octet-stream",
                    filename=filename,
                )
                print(f"Attachment added: {filename}")
            else:
                print(f"⚠️ Attachment not found: {path}")

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.send_message(msg)
        return True

    except Exception as e:
        print(f"❌ Error sending email: {e}")
        return False


if __name__ == "__main__":
    config_file = "email_config.ini"
    print(f"📧 | Sending email using configuration: {config_file}")
    print("=" * 60)

    success = send_email_from_config(config_file)

    if success:
        print("\n✅ Email sent successfully!")
    else:
        print("\n❌ Email sending failed!")
        print("\nTroubleshooting tips:")
        print("  1. Check your SMTP credentials")
        print("  2. Use App Passwords for Gmail")
        print("  3. Validate recipient emails")
        print("  4. Check your internet connection")
