provider "aws" {
  region = "us-east-1" # Change to your desired region
}

resource "aws_key_pair" "deployer" {
  key_name   = "my_key_trados1"                 # Change to your key pair name
  public_key = file("./my_key_trados2.pem.pub") # Path to your public key file
}

resource "aws_security_group" "allow_rdp" {
  name        = "allow_rdp"
  description = "Allow RDP traffic"

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "windows_server" {
  ami           = "ami-0ff0d292de1faaba9" # Change to the latest Windows Server AMI in your region
  instance_type = "t2.micro"              # Updated instance type
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.allow_rdp.id]

  #   user_data = <<-EOF
  #               <powershell>
  #               # Set Execution Policy
  #               Set-ExecutionPolicy Bypass -Scope Process -Force

  #               # Install Chocolatey
  #               [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
  #               iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

  #               # Install Google Chrome (Optional)
  #               choco install -y googlechrome

  #               # Set explorer.exe as the default shell
  #               Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon' -Name 'Shell' -Value 'explorer.exe'
  #               </powershell>
  #               EOF
  user_data = <<-EOF
              <powershell>
              # Set Execution Policy
              Set-ExecutionPolicy Bypass -Scope Process -Force

              # Install Chocolatey
              [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
              iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

              # Install Google Chrome (Optional)
              choco install -y googlechrome

              # Install Desktop Experience
              Install-WindowsFeature Server-Gui-Mgmt-Infra, Server-Gui-Shell -Restart

               # Ensure explorer.exe is the default shell
              Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Winlogon' -Name 'Shell' -Value 'explorer.exe'
          
              </powershell>
              EOF

  tags = {
    Name = "WindowsServerForTrados"
  }
}

output "public_ip" {
  description = "The public IP address of the Windows Server instance"
  value       = aws_instance.windows_server.public_ip
}
