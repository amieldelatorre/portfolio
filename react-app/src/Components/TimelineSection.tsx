import { FC } from "react";
import { Props } from "./Props";
import { VerticalTimeline, VerticalTimelineElement } from "react-vertical-timeline-component";
import 'react-vertical-timeline-component/style.min.css';
import { GetDatafromJSONInstance } from "../data/GetDataFromJSON";
import { Experience } from "../models/Experience";
import { IGetData } from "../data/IGetData";


const getVerticalTimelineElements = () => {
    const dataInput: IGetData = GetDatafromJSONInstance;

    let experiences: Experience[] = dataInput.getExperienceData();

    const timelineElements = experiences.map((exp) => {
        console.log(exp)
        return(
            <VerticalTimelineElement
                key={exp.sortOrder}
                className={`vertical-timeline-element--${exp.type}`}
                contentStyle={{ background: '#e8e4e4', color: 'black' }}
                contentArrowStyle={{ borderRight: '7px solid  rgb(33, 150, 243)' }}
                date={exp.dateRange}
                iconStyle={{ background: 'rgb(33, 150, 243)', color: '#fff' }}
            >
                <h3 className="vertical-timeline-element-title">{exp.title}</h3>
                <h4 className="vertical-timeline-element-subtitle">{exp.location}</h4>
                <p>{exp.description}</p>
            </VerticalTimelineElement>
        )
    });


    return (<>{timelineElements}</>)
}


export const TimelineSection: FC<Props> = (props) => {    
    return (
        <div className="timeline-section">
            <VerticalTimeline> 
                {getVerticalTimelineElements()}                
            </VerticalTimeline>
        </div> 
    )
};