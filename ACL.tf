# ACL Pública para prod
resource "aws_network_acl" "public_acl_prod" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "public-acl-prod"
  }
}

resource "aws_network_acl_rule" "public_inbound_prod" {
  network_acl_id = aws_network_acl.public_acl_prod.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_outbound_prod" {
  network_acl_id = aws_network_acl.public_acl_prod.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "public_acl_assoc_prod" {
  network_acl_id = aws_network_acl.public_acl_prod.id
  subnet_id      = aws_subnet.public_subnet_prod.id
}

# ACL Privada para prod
resource "aws_network_acl" "private_acl_prod" {
  vpc_id = aws_vpc.prod_vpc.id

  tags = {
    Name = "private-acl-prod"
  }
}

resource "aws_network_acl_rule" "private_inbound_prod" {
  network_acl_id = aws_network_acl.private_acl_prod.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_outbound_prod" {
  network_acl_id = aws_network_acl.private_acl_prod.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "private_acl_assoc_prod" {
  network_acl_id = aws_network_acl.private_acl_prod.id
  subnet_id      = aws_subnet.private_subnet_prod.id
}