# Public-read bucket, so a provider's fetch-from-URL needs no credentials and no
# secret ever reaches the node.
export def publish [src: path, id: string, creds: record] {
  let key = $"images/nomad-($id).img"

  with-env {
    RCLONE_CONFIG_R2_TYPE: "s3"
    RCLONE_CONFIG_R2_PROVIDER: "Cloudflare"
    RCLONE_CONFIG_R2_ACCESS_KEY_ID: $creds.access_key_id
    RCLONE_CONFIG_R2_SECRET_ACCESS_KEY: $creds.secret_access_key
    RCLONE_CONFIG_R2_ENDPOINT: $"https://($creds.account_id).r2.cloudflarestorage.com"
    RCLONE_CONFIG_R2_NO_CHECK_BUCKET: "true"
  } {
    rclone copyto ($src | path join "nomad.img") $"R2:($creds.bucket)/($key)"
  }

  $"($creds.public_base)/($key)"
}
