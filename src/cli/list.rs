pub fn list() {
    match get_apps_list() {
        Ok(apps) => {
            log::info!("App Chain: {:?}", apps);
        }
        Err(err) => {
            panic!("Failed to list: {}", err);
        }
    }
}

fn get_apps_list() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let apps = vec!["app1".to_string(), "app2".to_string()];
    Ok(apps)
}
