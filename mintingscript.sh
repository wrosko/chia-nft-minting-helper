#! /bin/bash

# Requirements : 

# To use this script, you must have the Chia client installed from source on a Linux operating system.
# It must be version 1.4 or greater.
# You also need an NFT wallet linked to a DID wallet (instructions can be found in Chia's NFT tutorial).
# Your wallet must be running and synced before running the script.

# Images must all be saved in a directory called 'images' which is a subfolder of the folder this script is running in.
# Each image should be saved as 'image[number].jpg', ex: image1.jpg, image2.jpg, image3.jpg, ...

# Each metadata file should be saved as 'metadata[number].json', which the numbers corresponding to the image numbers
# . ex: metadata1.json, metadata2.json, metadata3.json, etc...

# The user-supplied variables below must be customized 

# ------------ START USER-SUPPLIED VARIABLES------------------

# Extension of your images
img_ext=".jpeg"

# Total number to mint with this script. Should match the number of image files and number of metadata files.
total_num_to_mint=30

# Total number in NFT Collection. Will be recorded permanently on each NFT.
total_num_in_series=30

# NFT Wallet Fingerprint (Found in chia client CLI)
nft_wallet_fingerprint=1731819744

# NFT Wallet ID (found in Chia client CLI)
nft_wallet_id=8

# Address loyalty rewards will go to
royalty_wallet_address='xch103m57yshjuualzslespw4jgg4lgc5jufzmdtn77xkdt2erhtk9hqzp0ynr'

# Address the NFT will go to once minted
wallet_to_recieve_nft='xch103m57yshjuualzslespw4jgg4lgc5jufzmdtn77xkdt2erhtk9hqzp0ynr'

# Royalty percentage as a whole integer. Ex. '8' will be 8%
royalty_percentage=8

#Minting fee, in XCH
blockchain_minting_fee=0.00005

# Directory this file is in. Probably no need to change this
localdir="./"

# Directory your chia client exists in. Must be version 1.4 or greater with CLI (installed from source). 
chia_dir='~/chia-blockchain'

# This variable represents the number that the script will start at. If you get an error and have to restart the script, you can change this to the number you stopped at, so that it won't try to mint the same nft twice
i=1

# -------------- END USER-SUPPLIED  VARIABLES---------------------

while (( $i <= $total_num_to_mint ))
do
	# Check if image exists
	FILE=${localdir}images/image${i}${img_ext}
	if [ ! -f "$FILE" ]; then
		echo "User-specified image path ${localdir}images/image${i}${img_ext} does not exist! Check settings. Now exiting."
		exit
	fi

	# Check if metadata exists
	FILE=${localdir}metadata/metadata${i}.json
	if [ ! -f "$FILE" ]; then
		echo "User-specified metadata path ${localdir}metadata/metadata${i}.json does not exist! Check settings. Now exiting."
		exit
	fi

	f= "${localdir}images/image${i}${img_ext}"

	# Read image CID and return CID as variable
	read -p "Image $i CID: " image_cid
	image_url="https://${image_cid}.ipfs.nftstorage.link"

	# Check if hash of image locally and online match, then save hash as variable
	local_image_hash=$(sha256sum ${localdir}images/image${i}${img_ext} | head -c 64)
	remote_image_hash=$(curl -s $image_url | sha256sum | head -c 64)
	if [ $remote_image_hash == $local_image_hash ]
	then
		echo "Remote hash matches local hash! Proceeding"
		echo $image_url
	else
		echo "Remote hash does not match local hash. Possible user error. Exiting now."
		echo "url: $image_url hash of local file: $local_image_hash hash of remote file: $remote_image_hash"
		exit
	fi

	# Read metadata and return CID as variable
	read -p "Metadata $i CID: " metadata_cid
	metadata_url="https://${metadata_cid}.ipfs.nftstorage.link"
	
	# Check if hash of metadata locally and online match, then save hash as variable
	local_metadata_hash=$(sha256sum ${localdir}metadata/metadata${i}.json | head -c 64)
	remote_metadata_hash=$(curl -s $metadata_url | sha256sum | head -c 64)
	if [ $remote_metadata_hash == $local_metadata_hash ]
	then
		echo "Remote hash matches local hash! Proceeding"
		echo $metadata_url
	else
		echo "Remote hash does not match local hash. Possible user error. Exiting now."
		echo "url: $metadata_url hash of local file: $local_metadata_hash hash of remote file: $remote_metadata_hash"
		exit
	fi

	# Create command & Validate with user
	echo "Please validate the minting details before execution:"
	read -p "chia wallet nft mint -f $nft_wallet_fingerprint -i $nft_wallet_id -ra $royalty_wallet_address -ta $wallet_to_recieve_nft -u $image_url -nh $local_image_hash -mu $metadata_url -mh $local_metadata_hash -sn $i -st $total_num_in_series -rp $royalty_percentage -m $blockchain_minting_fee \n Would you like to mint your NFT? Final answer (y/n)" response
       if [ $response == "y" ]
       then
		echo "Proceeding to mint..."
 	else
		echo "Mint cancelled!"
		exit
	fi		

       	

	# Start Chia and Execute minting command
	cd ~/chia-blockchain
	. ./activate
	chia wallet nft mint -f $nft_wallet_fingerprint -i $nft_wallet_id -ra $royalty_wallet_address -ta $wallet_to_recieve_nft -u $image_url -nh $local_image_hash -mu $metadata_url -mh $local_metadata_hash -sn $i -st $total_num_in_series -rp $royalty_percentage -m $blockchain_minting_fee
	deactivate
	i=$((i+1))
done



