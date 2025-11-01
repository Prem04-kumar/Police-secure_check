import pandas as pd
import streamlit as st
import pymysql


def create_connection():
    try:
        conn = pymysql.connect(
            host='localhost',
            user='root',
            password='root',
            database='securecheck',
            cursorclass=pymysql.cursors.DictCursor
        )
        return conn
    except Exception as e:
        st.error(f"Database connection error: {e}")
        return None

def fetch_data(query):
    conn = create_connection()
    if conn:
        try:
            with conn.cursor() as cursor:
                cursor.execute(query)
                result = cursor.fetchall()
                columns = [desc[0] for desc in cursor.description]
                data = pd.DataFrame(result, columns=columns)
                return data
        finally:
            conn.close()
    else:
        return pd.DataFrame()
    
import asyncio

async def get(self):
    try:
        await self.flush()
    except asyncio.CancelledError:
        pass


st.set_page_config(page_title="securecheck police log dashboard", layout="wide")
st.title("securecheck:Police Check Post Digital Legder")
st.markdown("Real-time monitoring and insights for law inforcement")
st.header("police logs overview")
query = "SELECT * FROM police_logs"
data = fetch_data(query)
st.dataframe(data, use_container_width=True)
st.header("Key metrics")
col1, col2, col3, col4 = st.columns(4)

with col1:
    total_stops = data.shape[0]
    st.metric("Total police stops", total_stops)
    
with col2:
    arrests = data[data['stop_outcome'].str.contains("arrest",case=False, na=False)].shape[0]
    st.metric("Total Arrests", arrests)

with col3:
    warnings = data[data['stop_outcome'].str.contains("Warning", case=False, na=False)].shape[0]
    st.metric("Total Warnings", warnings)

with col4:
    drug_related = data[data['drugs_related_stop'] == 1].shape[0]
    st.metric("drugs_related_stop", drug_related)

st.header("Advanced insights")

selected_query = st.selectbox("Select a query to Run", [
    "Total Number of police Stops",
    "Count of Stops by Violation type",
    "Number of Arrests vs. Warnings",
    "Average Age of Drivers Stopped",
    "Top 5 Most Frequent Search Types",
    "Count of Stops by Gender",
    "Most Common Violation for Arrests",
    "Most Common Violation for Arrests Among Drivers Older Than 25",
    "Rare Violations Leading to Arrests or Searches",
    "Highest Rate of Drug-Related Stops by Country",
    "Arrest Rate by Country and Violation",
    "Most Stops with Search Conducted"
])



query_map = {
    "Total Number of police Stops": "SELECT COUNT(*) AS total_stops FROM police_logs",
    "Count of Stops by Violation type": "SELECT violation, COUNT(*) AS count FROM police_logs GROUP BY violation ORDER BY count DESC",
    "Number of Arrests vs. Warnings": "SELECT stop_outcome, COUNT(*) AS count FROM police_logs GROUP BY stop_outcome",
    "Average Age of Drivers Stopped": "SELECT AVG(driver_age) AS average_age FROM police_logs",
    "Top 5 Most Frequent Search Types": "SELECT search_type, COUNT(*) AS count FROM police_logs WHERE search_type != '' GROUP BY search_type ORDER BY count DESC LIMIT 5",
    "Count of Stops by Gender": "SELECT driver_gender, COUNT(*) AS count FROM police_logs GROUP BY driver_gender",
    "Most Common Violation for Arrests": "SELECT violation, COUNT(*) AS count FROM police_logs WHERE stop_outcome LIKE '%arrest%' GROUP BY violation ORDER BY count DESC LIMIT 1",
    "Most Common Violation for Arrests Among Drivers Older Than 25": "SELECT violation, COUNT(*) AS arrest_count FROM police_logs WHERE driver_age > 25 AND LOWER(stop_outcome) LIKE '%arrest%' GROUP BY violation ORDER BY arrest_count DESC LIMIT 1",
    "Rare Violations Leading to Arrests or Searches": "SELECT violation, COUNT(*) AS count FROM police_logs WHERE stop_outcome LIKE '%arrest%' OR search_conducted = TRUE GROUP BY violation ORDER BY count ASC",
    "Highest Rate of Drug-Related Stops by Country": "SELECT country_name, COUNT(*) AS count FROM police_logs WHERE drugs_related_stop = TRUE GROUP BY country_name ORDER BY count DESC LIMIT 1",
    "Arrest Rate by Country and Violation": "SELECT country_name, violation, COUNT(*) AS total_stops FROM police_logs WHERE stop_outcome LIKE '%arrest%' GROUP BY country_name, violation ORDER BY total_stops DESC",
    "Most Stops with Search Conducted": "SELECT country_name, violation, COUNT(*) AS search_conducted_count FROM police_logs WHERE search_conducted = TRUE GROUP BY country_name, violation ORDER BY search_conducted_count DESC LIMIT 1"
}

if st.button("Run Query"):
    result = fetch_data(query_map[selected_query])
    if not result.empty:
        st.write(result)
    
    else:
        st.warning("No results found for the selected query.")

st.header("Predict outcome and violations of the police logs")

with st.form("new_log_form"):
    stop_date = st.date_input("Stop date")
    stop_time = st.time_input("Stop time")
    country_name = st.text_input("Country name")
    driver_gender = st.selectbox("Driver gender", ["male", "Female"])
    driver_age = st.number_input("Driver age", min_value=16, max_value=100, value=27)
    driver_race = st.text_input("Driver race")
    search_conducted = st.selectbox("Was a search conducted?", ["0", "1"])
    search_type = st.text_input("Search type")
    drugs_related_stop = st.selectbox("Was it drug related?", ["0", "1"])
    stop_duration = st.selectbox("Stop duration", data['stop_duration'].dropna().unique())
    vehicle_number = st.text_input("Vehicle number")
    timestamp = pd.Timestamp.now()

    submitted = st.form_submit_button("Predict stop outcome & violation")

    filtered_data = pd.DataFrame()

    if submitted:
        filtered_data = data[
            (data['driver_gender'] == driver_gender) &
            (data['driver_age'] == driver_age) &
            (data['search_conducted'] == int(search_conducted)) &
            (data['stop_duration'] == stop_duration) &
            (data['drugs_related_stop'] == int(drugs_related_stop))
        ]

if not filtered_data.empty:
    predicted_outcome = filtered_data['stop outcome'].mode()[0]
    predicted_violation = filtered_data['violation'].mode()[0]
else:
    predicted_outcome = "warning"
    predicted_violation = "speeding"

search_text = "A serach was conducted" if int(search_conducted) else "No search was conducted"
drug_text = "was drug-related" if int(drugs_related_stop) else "was not drug-related"

st.markdown(f"""
** prediction summary**
    
** prediction violation**
** prediction stop outcome":** {predicted_outcome}

A (driver_age)-year-old {driver_gender} driver in {country_name} was stopped at {stop_time.strftime('%I:%M:%p')} on {stop_date}
{search_text}, and the stop {drug_text}.
stop duration: **{stop_duration}**
vehicle number: **{vehicle_number}**.
""")
            
















