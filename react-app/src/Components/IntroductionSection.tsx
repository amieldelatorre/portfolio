import { FC } from "react";
import { Props } from "./Props";
import silhouette from "../assets/user-silhouette-svgrepo-com.svg";


const getYearsOfExperience = () => {
    const dateStarted: Date = new Date(2021, 11); 
    let dateNow: Date = new Date();
    const secondsInAYear = 31536000 // 60 * 60 * 24 * 365;
    const experienceMilliSeconds: number = dateNow.valueOf() - dateStarted.valueOf();
    const experienceInSeconds: number = experienceMilliSeconds / 1000;
    return (experienceInSeconds/secondsInAYear).toFixed(1);
}


export const IntroductionSection: FC<Props> = (props) => {
    return (
        <div className="introduction-section">
            <img src={silhouette} height="400px"/>
            <p className="introduction-section-text"> Hi, I'm [redacted]. Software developer who is curious and still hungry to learn. Finished my studies in November 2021 and have been working since December 2021 with {getYearsOfExperience()} years of professional experience.</p>
        </div>
        
    )
};