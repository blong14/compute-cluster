function prod-bastion
	gcloud compute ssh prod-bastion-host --project $NOMAD_PROD_PROJECT --zone us-east1-c
end

