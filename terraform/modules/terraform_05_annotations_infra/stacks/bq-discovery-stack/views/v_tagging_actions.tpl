SELECT
th.start_time,
th.run_id,
th.tracker,
th.project_id,
th.dataset_id,
th.table_id,
th.field_id,
m.info_type,
th.existing_policy_tag,
th.new_policy_tag,
th.operation,
th.details
FROM `${project}.${dataset}.${v_log_tag_history}` th
INNER JOIN `${project}.${dataset}.${v_config_infotypes_policytags_map}` m
ON th.new_policy_tag = m.policy_tag
ORDER BY tracker