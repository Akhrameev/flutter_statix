import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class PythonScriptExecutor {
  static const String pythonScriptContent = '''
import smtplib
from email.message import EmailMessage
import os
import configparser
from typing import List, Dict, Optional

def read_config_file(config_path: str = "email_config.ini") -> Optional[Dict]:
    try:
        config = configparser.ConfigParser()
        config.read(config_path)
        config_dict = {
            'smtp': dict(config['SMTP']) if 'SMTP' in config else {},
            'email': dict(config['EMAIL']) if 'EMAIL' in config else {},
            'recipients': [],
            'attachments': []
        }
        if 'RECIPIENTS' in config:
            recipients_section = config['RECIPIENTS']
            config_dict['recipients'] = [
                email.strip() for email in recipients_section.get('emails', '').split(',')
                if email.strip()
            ]
        if 'ATTACHMENT' in config:
            attachment_section = config['ATTACHMENT']
            for key in attachment_section:
                value = attachment_section.get(key)
                if value:
                    config_dict['attachments'].append(value.strip())
        return config_dict
    except FileNotFoundError:
        print(f"Configuration file not found: {config_path}")
        return None
    except Exception as e:
        print(f"Error reading configuration file: {e}")
        return None

def send_email_from_config(config_path: str = "email_config.ini") -> bool:
    config = read_config_file(config_path)
    if not config:
        print("Failed to read configuration file")
        return False
    smtp = config['smtp']
    smtp_server = smtp.get('server', 'smtp.gmail.com')
    smtp_port = int(smtp.get('port', '587'))
    smtp_user = smtp.get('username', '')
    smtp_pass = smtp.get('password', '')
    email_config = config['email']
    email_from = email_config.get('from', smtp_user)
    subject = email_config.get('subject', 'Build Notification')
    body = email_config.get('body', 'Build completed successfully.')
    recipients = config['recipients']
    if not recipients:
        recipients = [email_config.get('to', '')]
    attachments = config['attachments']
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
        for path in attachments:
            if os.path.exists(path):
                with open(path, "rb") as f:
                    data = f.read()
                    filename = os.path.basename(path)
                msg.add_attachment(data, maintype="application", subtype="octet-stream", filename=filename)
                print(f"Attachment added: {filename}")
            else:
                print(f"⚠️ Attachment not found: {path}")
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(smtp_user, smtp_pass)
            server.send_message(msg)
        print("\\n✅  | Email sent successfully!")
        return True
    except Exception as e:
        print(f"❌  | Error Sending Email: {e}")
        return False

if __name__ == "__main__":
    config_file = "email_config.ini"
    print(f"📧 | Sending Email Using Configuration: {config_file}")
    print("=" * 60)
    send_email_from_config(config_file)
''';

  static Future<void> decodeAndExecute() async {
    try {
      final scriptDir = path.dirname(Platform.script.toFilePath());
      final scriptPath = path.join(scriptDir, 'temp_send_email.py');

      // Write Python content to temp file
      final file = File(scriptPath);
      await file.writeAsString(pythonScriptContent);

      await executePythonScript(scriptPath);

      // Clean up
      await file.delete();
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  static Future<void> executePythonScript(String scriptPath) async {
    try {
      print('🚀 | Sending E-Mail...');
      List<String> pythonCommands = ['python3', 'python', 'py'];
      Process? process;

      for (String cmd in pythonCommands) {
        try {
          process = await Process.start(cmd, [scriptPath]);
          break;
        } catch (_) {}
      }

      if (process == null) {
        throw Exception('Python interpreter not found.');
      }

      process.stdout.transform(utf8.decoder).listen((data) => stdout.write(data));
      process.stderr.transform(utf8.decoder).listen((data) => stderr.write(data));

      await process.exitCode;
    } catch (e) {
      print('❌  | Something went Wrong: $e');
      rethrow;
    }
  }
}

Future<void> main() async {
  await PythonScriptExecutor.decodeAndExecute();
}
