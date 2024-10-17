#################### DATA ####################

##### What's my IP? (from where you are running terraform)
# Fetches the public IPv6 address
data "http" "myip6" {
  url = "https://icanhazip.com"
}

# Fetches the public IPv4 address
data "http" "myip4" {
  url = "https://ipv4.icanhazip.com"
}
