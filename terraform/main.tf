terraform {
  required_version = ">= 0.12"
  backend "s3" {
    bucket = "myapp-tf-s3-bucket-zerze"
    key    = "myapp/state.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = var.region
}


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"   /* Δες πως περνάω το variable μέσα σε ένα string --> ${var.env_prefix} */
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = var.avail_zone
    tags = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

/* 
ΔΗΜΙΟΥΡΓΙΑ ΝΕΟΥ ROUTE TABLE 
  (resources: aws_route_table, aws_route_table_association)
*/

/*
resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  
  // ΕΔΩ θα προσθέσουμε τα routes που θέλουμε επιπλέον. 
  // ΠΡΟΣΟΧΗ δεν θα φτιάξουμε το default route που δημιουργείται αυτόματα
  //  όταν φτιάχνεται ένα route table. 
  // Εμείς απλά θα προσθέσουμε ότι επιπλέον θέλουμε (πχ το 0.0.0.0/0)

  route {

    // Σε ένα route 2 πράγματα πρέπει να καθορίσω:
    //  1) cidr_block
    //  2) gateway_id
  
    cidr_block = "0.0.0.0/0"
     
    // Δεν έχουμε κάποιο Internet Gateway, καθώς ΔΕΝ φτιάχνεται μόνο του.
    // Οπότε πρέπει να φτιάξουμε ένα, δες παρακάτω, και να το κάνουμε reference εδώ μέσα

    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb" 
  }
}
*/

resource "aws_internet_gateway" "myapp-igw" {
  /*
  Για το aws_internet_gateway το μόνο που πρέπει να καθορίσω είναι το vpc_id στο οποίο θα δημιουργηθεί το igw
  */
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name = "${var.env_prefix}-igw" 
  }
}

/*
  Πρέπει να κάνουμε associate το subnet που φτιάξαμε με το route table που φτιάξαμε
*/
/*
resource "aws_route_table_association" "a-rtb-subnet" {
  subnet_id = aws_subnet.myapp-subnet-1.id
  route_table_id = aws_route_table.myapp-route-table.id
}
*/


/* 
ΧΡΗΣΙΜΟΠΟΙΗΣΗ ΤΟΥ DEFAULT ROUTE TABLE ΠΟΥ ΦΤΙΑΧΝΕΤΑΙ ΑΥΤΟΜΑΤΑ ΟΤΑΝ ΦΤΙΑΧΝΩ ΕΝΑ VPC
*/
resource "aws_default_route_table" "main-rtb" {
  // Θέλω να βρω το id και να κάνω reference σε ένα ήδη υπάρχον route table
  // Το id από αυτό το default_route_table_id θα το βρω από το aws_vpc.myapp-vpc
  // Μπορώ γιατί όταν έφτιαξα το myapp-vpc, τότε αυτόματα φτιάχτηκε και το default route table
  // Για να δω ακριβώς το id από το ήδη υπάρχων route table, τότε πάω και τρέσω την εντολή
  // terraform show aws_vpc.myapp-vpc
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {

    // Σε ένα route 2 πράγματα πρέπει να καθορίσω:
    //  1) cidr_block
    //  2) gateway_id
  
    cidr_block = "0.0.0.0/0"
     
    // Δεν έχουμε κάποιο Internet Gateway, καθώς ΔΕΝ φτιάχνεται μόνο του.
    // Οπότε πρέπει να φτιάξουμε ένα, δες παρακάτω, και να το κάνουμε reference εδώ μέσα

    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-main-rtb" 
  }
}

/*
  CREATE NEW SECURITY GROUP FOR ACCESS THE EC2 INSTANCES
*/
/*
resource "aws_security_group" "myapp-sg" {
  name= "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

   
  //  Rules για incoming traffic  -> για ssh, access from a browser
  
  ingress{
    
    // Βάζω το Range από τις πόρτες που ανοίξω
    //  Εγώ εδώ θέλω μόνο την πόρτα 22 --> οπότε from_port = 22 μέχρι την πόρτα to_port = 22
    //  Αν πχ ήθελα να ανοίξω τις πόρτεσ 65000 - 65100 θα έβαζα: from_port = 65000 μέχρι την πόρτα to_port = 65100
    
    from_port = 22  
    to_port = 22
    protocol = "TCP"
    // Εδώ μέσα μπορώ να βάλω μια λίστα με τις IPs που επιτρέπεται να κάνουν ssh στον server (το EC2 instance)
    // Ο καλύτερος τρόπος είναι να φτιάξω ένα variable και να μην το έχω hardcoded γιατί μπορεί να αλλάζει συνέχεια η IP μου,
    // οπότε καλύτερα να το αλλάζω από το .tfvars και να μην το ψάχνω μέσα στο main.tf
    cidr_blocks = [var.my_ip]  
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"] // SOS δεν πως το περνάω μέσα στη λίστα. Είναι string!!!
  }


   
  //  Rules για outcoming traffic  -> αυτό το θέλω ώστε ο server να μπορεί να βγαίνει στο Internet πχ για να κανει κάποιο Installation, ή να κάνει fetch ένα Docker image
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"  // Βάζω -1 που σημαίνει ΟΠΟΙΟΔΗΠΟΤΕ πρωτόκολλο
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []  // For allowing access for vpc endopoints, για να επιτρέπει να φευγει κίνηση από το ίδιο το vpc και τους ίδιους τους server
  }

  tags = {
    Name = "${var.env_prefix}-sg" 
  }

} 
*/

/*
  MODIFY THE DEFAULT SECURITY GROUP FOR ACCESS THE EC2 INSTANCES
*/
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id
   
  //  Rules για incoming traffic  -> για ssh, access from a browser
  
  ingress{
    
    // Βάζω το Range από τις πόρτες που ανοίξω
    //  Εγώ εδώ θέλω μόνο την πόρτα 22 --> οπότε from_port = 22 μέχρι την πόρτα to_port = 22
    //  Αν πχ ήθελα να ανοίξω τις πόρτεσ 65000 - 65100 θα έβαζα: from_port = 65000 μέχρι την πόρτα to_port = 65100
    
    from_port = 22  
    to_port = 22
    protocol = "TCP"
    // Εδώ μέσα μπορώ να βάλω μια λίστα με τις IPs που επιτρέπεται να κάνουν ssh στον server (το EC2 instance)
    // Ο καλύτερος τρόπος είναι να φτιάξω ένα variable και να μην το έχω hardcoded γιατί μπορεί να αλλάζει συνέχεια η IP μου,
    // οπότε καλύτερα να το αλλάζω από το .tfvars και να μην το ψάχνω μέσα στο main.tf
    cidr_blocks = [var.my_ip, var.jenkins_ip]  
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"] // SOS δεν πως το περνάω μέσα στη λίστα. Είναι string!!!
  }


   
  //  Rules για outcoming traffic  -> αυτό το θέλω ώστε ο server να μπορεί να βγαίνει στο Internet πχ για να κανει κάποιο Installation, ή να κάνει fetch ένα Docker image
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"  // Βάζω -1 που σημαίνει ΟΠΟΙΟΔΗΠΟΤΕ πρωτόκολλο
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []  // For allowing access for vpc endopoints, για να επιτρέπει να φευγει κίνηση από το ίδιο το vpc και τους ίδιους τους server
  }

  tags = {
    Name = "${var.env_prefix}-default-sg" 
  }

}


/*
===================================================
===================================================

            CREATE THE EC2 INSTANCE

===================================================
===================================================
*/

/*
  Πρώτα πρέπει να μαθαίνω δυναμικά το ami id που θα εγκαταστήσω στο 
  EC2 instance ώστε να μην το βάζω hardcoded
  Στο συγκεκριμένο παράδειγμα θέλω να μαθαίνω το latest amazon linux image
*/
//ΠΑΛΙΟΣ ΤΡΟΠΟΣ -> όταν μέσα στο Community AMI έβλεπες κανονικά το όνομα 
/*
data "aws_ami" "latest-amazon-linux-image" {
  most-recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-kernel-*-x86_64_gp2"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}
*/

/*
  ΝΕΟΣ ΤΡΟΠΟΣ -> χρησιμοποιώ τα System Manager public parameters. Συγκεκριμένα η Public parameter
    /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 θα μου επιστρέψει το ami που θέλω.
*/
data "aws_ssm_parameter" "latest-amazon-linux-image" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}



output "ami_aws_id" {
  value = nonsensitive(data.aws_ssm_parameter.latest-amazon-linux-image.value)
}

/*
  Δημιουργία key-pair χρησιμοποιώντας το ΔΙΚΟ ΜΟΥ public key
  Εδώ ΔΕΝ φτιάχνουμε καινούργιο key-pair οπότε δεν το θέλουμε το resource για το aws_key_pair  
*/
/*
resource "aws_key_pair" "ssh-key" {
  key_name = "myapp-server-key"

  // Public key hard-coded
  // public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILvq2VTexEW2lmi65XEck04LOu5H0/p90ps0AwNQ1iYs nickzerz92@hotmail.com"

  // Public key μέσω variable
  // public_key = var.my_public_key

  // Public key δηλώνοντας τη θέση του αρχείου
  public_key = file(var.my_public_key_location)
}
*/

resource "aws_instance" "myapp-server" {
  // Παλιός τρόπος
  // ami = data.aws_ami.latest-amazon-linux-image.id

  // Νέος τρόπος μέσω του System Manager public parameter
  ami = data.aws_ssm_parameter.latest-amazon-linux-image.value

  instance_type = var.instance_type

  // Το δένω με το σωστό subnet που έφτιαξα
  subnet_id = aws_subnet.myapp-subnet-1.id

  // Το δένω και με το σωστό security group
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]

  // Το δένω και με το σωστό availability zone
  availability_zone = var.avail_zone

  // Του δίνω και public IP address
  associate_public_ip_address = true

  // Κάνω bind με ένα καινούργιο key-pair που έχω φτιάξει μόνος μου μέσα στο AWS και έχω αποθηκεύσει το .pem αρχείο στο μηχάνημά μου
  //key_name = "myapp-server-key-pair"

  // Βάζω καρφωτά το όνομα του key-pair που φτιάξαμε manual στο AWS συγκεκριμένα για το Jenkins
  key_name = "myapp-key-pair-for-jenkins"


  /*
  Εντολές για να κάνω εγκαταστάσεις μέσα στο ec2-instance που έφτιαξα

  ΤΡΟΠΟΣ 1: γράφω στο user_data ακριβώς τις εντολές που θέλω να τρέξουν
  */ 
  /*
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                docker run -p 8080:80 nginx
              EOF
  */

  /*
  ΤΡΟΠΟΣ 2: περνάω ένα script μέσα στο user_data αντί για να έχω εδώ όλες τις εντολές.
  */ 
  user_data = file("entry-script.sh")

  user_data_replace_on_change = true

  tags = {
    Name = "${var.env_prefix}-myapp-server" 
  }
}

output "ec2_public_ip" {
  //Με "terraform state show aws_instance.myapp-server" βλέπω ποιο είναι το attribute που θα μου επιστρέφει την public IP
  value = aws_instance.myapp-server.public_ip
}
  