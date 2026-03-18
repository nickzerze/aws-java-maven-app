variable vpc_cidr_block {
    // Βάζω μια default τιμή ώστε να μην πρέπει συνέχεια να ενημερώνω το .tfvars αρχείο.
    default = "10.0.0.0/16"
}
variable subnet_cidr_block {
    default = "10.0.10.0/24"
}
variable avail_zone {
    default = "eu-central-1a"
}
variable env_prefix {
    default = "dev"
} /*Αυτό το θέλουμε για να το περνάω στα ονόματα από τα resources που θα φτιάχνω, πχ θα έχω dev, prod, ...*/
variable my_ip {
    // Αυτό το θέλουμε για να μπορώ να κάνω ssh connection από το pc μου στο EC2-instance που θα φτιαχτεί
    default = "195.251.1.7/32"
}
variable jenkins_ip {
    default = "3.125.9.243/32"
}

variable instance_type {
    default = "t3.small"
}
variable region {
    default = "eu-central-1"
}