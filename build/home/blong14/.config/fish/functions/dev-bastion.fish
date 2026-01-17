function dev-bastion
	gcloud compute ssh dev-bastion-host --project $NOMAD_DEV_PROJECT --zone us-east1-c
end

