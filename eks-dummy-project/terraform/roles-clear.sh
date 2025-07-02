#!/bin/bash

CLUSTER_ROLE="eks-dummy-test-cluster-role"
NODE_ROLE="eks-dummy-test-node-role"

# Función para limpiar un rol
cleanup_role() {
    local role_name=$1
    
    echo "Limpiando rol: $role_name"
    
    # Desasociar políticas administradas
    aws iam list-attached-role-policies --role-name $role_name --query 'AttachedPolicies[].PolicyArn' --output text | while read policy_arn; do
        if [ ! -z "$policy_arn" ]; then
            echo "Desasociando política: $policy_arn"
            aws iam detach-role-policy --role-name $role_name --policy-arn $policy_arn
        fi
    done
    
    # Eliminar políticas inline
    aws iam list-role-policies --role-name $role_name --query 'PolicyNames' --output text | while read policy_name; do
        if [ ! -z "$policy_name" ]; then
            echo "Eliminando política inline: $policy_name"
            aws iam delete-role-policy --role-name $role_name --policy-name $policy_name
        fi
    done
    
    # Eliminar el rol
    echo "Eliminando rol: $role_name"
    aws iam delete-role --role-name $role_name
}

# Limpiar ambos roles
cleanup_role $CLUSTER_ROLE
cleanup_role $NODE_ROLE

# Eliminar log group
aws logs delete-log-group --log-group-name /aws/eks/eks-dummy-test/cluster

echo "Limpieza completada"