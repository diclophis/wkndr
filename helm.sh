#

#TODO:
# Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
# To prevent this, run `helm init` with the --tiller-tls-verify flag.

kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'      
helm init --tiller-tls-verify --service-account tiller --upgrade
